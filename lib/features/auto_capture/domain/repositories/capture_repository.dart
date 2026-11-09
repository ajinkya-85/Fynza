import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/capture_constants.dart';
import '../../../../core/di/database_provider.dart';
import '../../../../data/db/app_database.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../data/services/capture_dao.dart';
import '../../data/services/capture_dedupe.dart';
import '../../data/services/capture_preferences_service.dart';
import '../models/capture_item.dart';
import '../models/capture_status.dart';
import '../models/parsed_transaction.dart';
import '../models/raw_notification.dart';
import '../parsing/sms_transaction_parser.dart';

abstract class CaptureRepository {
  Stream<List<CaptureItem>> watchPendingCaptures();
  Stream<int> watchPendingCount();
  Stream<List<CaptureItem>> watchRecentlyAutoAdded({int limit = 10});

  Future<void> ingest(List<RawNotification> notifications);

  Future<void> confirmCapture(
    int captureId, {
    required int categoryId,
    String? note,
    DateTime? date,
    int? amountCents,
    TransactionType? type,
  });

  Future<void> dismissCapture(int captureId);
  Future<void> undoDismiss(int captureId);
  Future<void> undoAutoAdd(int captureId);
  Future<void> ignoreSender(String sender);
  Future<void> deleteAllCapturedData();
  Future<void> purgeOldCaptures({Duration retentionPeriod = const Duration(days: 90)});
  Future<int?> getSuggestedCategory(String counterparty);
}

class CaptureRepositoryImpl implements CaptureRepository {
  final AppDatabase _db;
  final CaptureDao _dao;
  final CapturePreferencesService _prefs;
  final SmsTransactionParser _parser;

  CaptureRepositoryImpl({
    required AppDatabase db,
    required this._prefs,
    CaptureDao? dao,
    SmsTransactionParser? parser,
  })  : _db = db,
        _dao = dao ?? db.captureDao,
        _parser = parser ?? const SmsTransactionParser();

  @override
  Stream<List<CaptureItem>> watchPendingCaptures() {
    return _dao.watchPendingCaptures().asyncMap((list) async {
      final items = <CaptureItem>[];
      for (var i = 0; i < list.length; i++) {
        final t = list[i];
        final isDuplicateInBatch = list.asMap().entries.any((entry) =>
            entry.key != i &&
            entry.value.amountCents == t.amountCents &&
            entry.value.occurredAt.difference(t.occurredAt).abs().inHours <= 24);
        final hasDbMatch = await _dao.hasMatchingLoggedTransaction(
          amountCents: t.amountCents,
          date: t.occurredAt,
        );
        items.add(_mapToDomain(
          t,
          isPossibleDuplicate: isDuplicateInBatch || hasDbMatch,
        ));
      }
      return items;
    });
  }

  @override
  Stream<int> watchPendingCount() {
    return _dao.watchPendingCount();
  }

  @override
  Stream<List<CaptureItem>> watchRecentlyAutoAdded({int limit = 10}) {
    return _dao
        .watchRecentlyAutoAdded(limit: limit)
        .map((list) => list.map(_mapToDomain).toList());
  }

  @override
  Future<void> ingest(List<RawNotification> notifications) async {
    if (!_prefs.isMasterEnabled()) return;

    for (final raw in notifications) {
      try {
        await _ingestSingle(raw);
      } catch (_) {
        // Never throw to caller, catch per item without logging sensitive text
      }
    }
  }

  Future<void> _ingestSingle(RawNotification raw) async {
    // 1. Source gate: SMS or Payment app package check
    final pkg = raw.packageName.trim().toLowerCase();
    final isSupported = CaptureConstants.isSupportedPackage(pkg);
    if (!isSupported) {
      return;
    }

    // 2. Sender gate:
    // If from a payment/banking app, the app or transaction title is valid.
    // If from an SMS app, enforce bank alphanumeric header.
    final sender = raw.title.trim();
    final isPaymentApp = CaptureConstants.knownPaymentPackages.any(
          (known) => pkg.contains(known.toLowerCase()) || known.toLowerCase().contains(pkg),
        ) ||
        pkg.contains('pay') ||
        pkg.contains('upi');

    if (!isPaymentApp && !_isValidBankSender(sender)) return;
    if (_prefs.isSenderIgnored(sender)) return;

    // 3. Parse
    final postDate = DateTime.fromMillisecondsSinceEpoch(raw.postTime);
    final parseResult = _parser.parse(raw.text, postDate);
    if (parseResult is! ParsedTransaction) return;

    // 4. Dedupe key
    final dedupeKey = CaptureDedupe.computeKey(
      amountCents: parseResult.amountCents,
      type: parseResult.type,
      reference: parseResult.reference,
      accountLast4: parseResult.accountLast4,
      sender: sender,
      rawText: raw.text,
    );

    // 5. Suggested category
    int? suggestedCatId;
    if (parseResult.counterparty != null) {
      final normCp = _normalizeCounterparty(parseResult.counterparty!);
      suggestedCatId = await _dao.getSuggestedCategory(normCp);
    }

    final mode = _prefs.getMode();
    final isAutoAddEligible =
        mode.isAddAutomatically && parseResult.confidence == ParseConfidence.high && suggestedCatId != null;

    if (isAutoAddEligible) {
      // In ONE Drift transaction: insert transaction, insert captured_transaction confirmed
      await _db.transaction(() async {
        final txId = await _db.into(_db.transactions).insert(
              TransactionsCompanion.insert(
                amount: parseResult.amountCents,
                type: parseResult.type,
                categoryId: suggestedCatId!,
                date: postDate,
                note: Value(parseResult.counterparty ?? 'Bank transaction'),
              ),
            );

        await _dao.insertCaptureOrIgnore(
          CapturedTransactionsCompanion.insert(
            amountCents: parseResult.amountCents,
            type: parseResult.type,
            counterparty: Value(parseResult.counterparty),
            accountLast4: Value(parseResult.accountLast4),
            reference: Value(parseResult.reference),
            occurredAt: postDate,
            capturedAt: DateTime.now(),
            sourcePackage: raw.packageName,
            sender: sender,
            dedupeKey: dedupeKey,
            status: CaptureStatus.confirmed,
            transactionId: Value(txId),
            suggestedCategoryId: Value(suggestedCatId),
          ),
        );
      });
    } else {
      // Insert as pending
      await _dao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          amountCents: parseResult.amountCents,
          type: parseResult.type,
          counterparty: Value(parseResult.counterparty),
          accountLast4: Value(parseResult.accountLast4),
          reference: Value(parseResult.reference),
          occurredAt: postDate,
          capturedAt: DateTime.now(),
          sourcePackage: raw.packageName,
          sender: sender,
          dedupeKey: dedupeKey,
          status: CaptureStatus.pending,
          suggestedCategoryId: Value(suggestedCatId),
        ),
      );
    }
  }

  @override
  Future<void> confirmCapture(
    int captureId, {
    required int categoryId,
    String? note,
    DateTime? date,
    int? amountCents,
    TransactionType? type,
  }) async {
    final capture = await _dao.getCaptureById(captureId);
    if (capture == null) return;

    final effectiveAmount = amountCents ?? capture.amountCents;
    final effectiveType = type ?? capture.type;
    final effectiveDate = date ?? capture.occurredAt;
    final effectiveNote = note ?? capture.counterparty ?? 'Bank transaction';

    await _db.transaction(() async {
      // Insert transaction
      final txId = await _db.into(_db.transactions).insert(
            TransactionsCompanion.insert(
              amount: effectiveAmount,
              type: effectiveType,
              categoryId: categoryId,
              date: effectiveDate,
              note: Value(effectiveNote),
            ),
          );

      // Set confirmed
      await _dao.updateCaptureStatus(
        captureId,
        CaptureStatus.confirmed,
        transactionId: txId,
      );

      // Update counterparty lookup rule
      if (capture.counterparty != null && capture.counterparty!.trim().isNotEmpty) {
        final norm = _normalizeCounterparty(capture.counterparty!);
        await _dao.setSuggestedCategory(norm, categoryId);
      }
    });
  }

  @override
  Future<void> dismissCapture(int captureId) async {
    await _dao.updateCaptureStatus(captureId, CaptureStatus.dismissed);
  }

  @override
  Future<void> undoDismiss(int captureId) async {
    await _dao.updateCaptureStatus(captureId, CaptureStatus.pending);
  }

  @override
  Future<void> undoAutoAdd(int captureId) async {
    final capture = await _dao.getCaptureById(captureId);
    if (capture == null || capture.transactionId == null) return;

    await _db.transaction(() async {
      // Delete transaction
      await (_db.delete(_db.transactions)..where((t) => t.id.equals(capture.transactionId!))).go();

      // Dismiss capture row
      await _dao.updateCaptureStatus(captureId, CaptureStatus.dismissed);
    });
  }

  @override
  Future<void> ignoreSender(String sender) async {
    await _prefs.addIgnoredSender(sender);
    await _dao.dismissPendingBySender(sender);
  }

  @override
  Future<void> deleteAllCapturedData() async {
    await _dao.deleteAllCaptures();
  }

  @override
  Future<void> purgeOldCaptures({Duration retentionPeriod = const Duration(days: 90)}) async {
    final cutoff = DateTime.now().subtract(retentionPeriod);
    await _dao.purgeOldCaptures(cutoff);
  }

  @override
  Future<int?> getSuggestedCategory(String counterparty) async {
    final norm = _normalizeCounterparty(counterparty);
    return _dao.getSuggestedCategory(norm);
  }

  bool _isValidBankSender(String sender) {
    if (sender.isEmpty) return false;
    // Bank headers typically: XX-ABCDEF, VK-HDFCBK, AX-SBIINB or short alphanumeric
    // Plain phone number like +919876543210 or 9876543210 -> not a bank header
    final digitsOnly = sender.replaceAll(RegExp(r'[\s+\-]'), '');
    if (RegExp(r'^\d+$').hasMatch(digitsOnly)) return false;

    // Check for standard hyphenated Indian header e.g. "AD-HDFCBK", "VK-SBI"
    if (RegExp(r'^[A-Za-z]{2}-[A-Za-z0-9]{3,8}', caseSensitive: false).hasMatch(sender)) {
      return true;
    }

    // Short alphanumeric ID without space e.g. "HDFCBK", "SBIINB"
    if (RegExp(r'^[A-Za-z0-9]{3,10}$').hasMatch(sender)) {
      return true;
    }

    return true; // Allow best-effort if passed SMS app filter
  }

  String _normalizeCounterparty(String cp) {
    return cp
        .toLowerCase()
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
  }

  CaptureItem _mapToDomain(CapturedTransaction t, {bool isPossibleDuplicate = false}) {
    return CaptureItem(
      id: t.id,
      amountCents: t.amountCents,
      type: t.type,
      counterparty: t.counterparty,
      accountLast4: t.accountLast4,
      reference: t.reference,
      occurredAt: t.occurredAt,
      capturedAt: t.capturedAt,
      sourcePackage: t.sourcePackage,
      sender: t.sender,
      dedupeKey: t.dedupeKey,
      status: t.status,
      transactionId: t.transactionId,
      suggestedCategoryId: t.suggestedCategoryId,
      isPossibleDuplicate: isPossibleDuplicate,
    );
  }
}

final captureRepositoryProvider = Provider<CaptureRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final prefs = ref.watch(capturePreferencesServiceProvider);
  return CaptureRepositoryImpl(db: db, prefs: prefs);
});
