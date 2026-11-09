import 'package:drift/native.dart';
import 'package:expense_tracker/data/db/app_database.dart';
import 'package:expense_tracker/features/auto_capture/domain/models/capture_status.dart';
import 'package:expense_tracker/shared/models/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('CaptureDao tests', () {
    test('insertCaptureOrIgnore deduplicates via dedupeKey', () async {
      final now = DateTime.now();
      final companion = CapturedTransactionsCompanion.insert(
        dedupeKey: 'unique_key_1',
        sourcePackage: 'com.google.android.apps.messaging',
        sender: 'HDFCBK',
        amountCents: 150000,
        type: TransactionType.expense,
        status: CaptureStatus.pending,
        occurredAt: now,
        capturedAt: now,
      );

      final id1 = await db.captureDao.insertCaptureOrIgnore(companion);
      expect(id1, isPositive);

      // Attempt inserting with same dedupeKey should be ignored
      await db.captureDao.insertCaptureOrIgnore(companion);

      final all = await db.captureDao.getAllCaptures();
      expect(all.length, 1);
      expect(all.first.id, id1);
    });

    test('watchPendingCount and watchPendingCaptures react to status changes', () async {
      final now = DateTime.now();
      expect(await db.captureDao.watchPendingCount().first, 0);

      await db.captureDao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          dedupeKey: 'key_1',
          sourcePackage: 'com.google.android.apps.messaging',
          sender: 'HDFCBK',
          amountCents: 1000,
          type: TransactionType.expense,
          status: CaptureStatus.pending,
          occurredAt: now,
          capturedAt: now,
        ),
      );

      await db.captureDao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          dedupeKey: 'key_2',
          sourcePackage: 'com.google.android.apps.messaging',
          sender: 'SBIBNK',
          amountCents: 2000,
          type: TransactionType.expense,
          status: CaptureStatus.pending,
          occurredAt: now.add(const Duration(minutes: 1)),
          capturedAt: now.add(const Duration(minutes: 1)),
        ),
      );

      expect(await db.captureDao.watchPendingCount().first, 2);

      final pendingList = await db.captureDao.watchPendingCaptures().first;
      expect(pendingList.length, 2);
      // Newest occurredAt first
      expect(pendingList.first.dedupeKey, 'key_2');

      // Update one to confirmed
      await db.captureDao.updateCaptureStatus(
        pendingList.first.id,
        CaptureStatus.confirmed,
      );

      expect(await db.captureDao.watchPendingCount().first, 1);
    });

    test('dismissPendingBySender dismisses all pending for that sender only', () async {
      final now = DateTime.now();
      await db.captureDao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          dedupeKey: 'key_1',
          sourcePackage: 'com.google.android.apps.messaging',
          sender: 'HDFCBK',
          amountCents: 1000,
          type: TransactionType.expense,
          status: CaptureStatus.pending,
          occurredAt: now,
          capturedAt: now,
        ),
      );

      await db.captureDao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          dedupeKey: 'key_2',
          sourcePackage: 'com.google.android.apps.messaging',
          sender: 'HDFCBK',
          amountCents: 2000,
          type: TransactionType.expense,
          status: CaptureStatus.pending,
          occurredAt: now,
          capturedAt: now,
        ),
      );

      await db.captureDao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          dedupeKey: 'key_3',
          sourcePackage: 'com.google.android.apps.messaging',
          sender: 'ICICIB',
          amountCents: 3000,
          type: TransactionType.expense,
          status: CaptureStatus.pending,
          occurredAt: now,
          capturedAt: now,
        ),
      );

      final dismissed = await db.captureDao.dismissPendingBySender('HDFCBK');
      expect(dismissed, 2);

      final pending = await db.captureDao.watchPendingCaptures().first;
      expect(pending.length, 1);
      expect(pending.first.sender, 'ICICIB');
    });

    test('purgeOldCaptures deletes confirmed and dismissed older than threshold', () async {
      final oldDate = DateTime.now().subtract(const Duration(days: 100));
      final recentDate = DateTime.now().subtract(const Duration(days: 10));

      // Old confirmed
      await db.captureDao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          dedupeKey: 'old_confirmed',
          sourcePackage: 'com.google.android.apps.messaging',
          sender: 'HDFCBK',
          amountCents: 1000,
          type: TransactionType.expense,
          status: CaptureStatus.confirmed,
          occurredAt: oldDate,
          capturedAt: oldDate,
        ),
      );

      // Old dismissed
      await db.captureDao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          dedupeKey: 'old_dismissed',
          sourcePackage: 'com.google.android.apps.messaging',
          sender: 'HDFCBK',
          amountCents: 1000,
          type: TransactionType.expense,
          status: CaptureStatus.dismissed,
          occurredAt: oldDate,
          capturedAt: oldDate,
        ),
      );

      // Old pending (should NOT be purged)
      await db.captureDao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          dedupeKey: 'old_pending',
          sourcePackage: 'com.google.android.apps.messaging',
          sender: 'HDFCBK',
          amountCents: 1000,
          type: TransactionType.expense,
          status: CaptureStatus.pending,
          occurredAt: oldDate,
          capturedAt: oldDate,
        ),
      );

      // Recent confirmed (should NOT be purged)
      await db.captureDao.insertCaptureOrIgnore(
        CapturedTransactionsCompanion.insert(
          dedupeKey: 'recent_confirmed',
          sourcePackage: 'com.google.android.apps.messaging',
          sender: 'HDFCBK',
          amountCents: 1000,
          type: TransactionType.expense,
          status: CaptureStatus.confirmed,
          occurredAt: recentDate,
          capturedAt: recentDate,
        ),
      );

      final purgedCount = await db.captureDao.purgeOldCaptures(
        DateTime.now().subtract(const Duration(days: 90)),
      );
      expect(purgedCount, 2);

      final remaining = await db.captureDao.getAllCaptures();
      expect(remaining.length, 2);
      final remainingKeys = remaining.map((r) => r.dedupeKey).toSet();
      expect(remainingKeys.contains('old_pending'), isTrue);
      expect(remainingKeys.contains('recent_confirmed'), isTrue);
    });

    test('Counterparty rules: get and set suggested category', () async {
      final categories = await db.categoryDao.getAllCategories();
      final catId = categories.first.id;

      expect(await db.captureDao.getSuggestedCategory('SWIGGY'), isNull);

      await db.captureDao.setSuggestedCategory('SWIGGY', catId);
      expect(await db.captureDao.getSuggestedCategory('SWIGGY'), catId);

      // Update to another category
      final catId2 = categories.last.id;
      await db.captureDao.setSuggestedCategory('SWIGGY', catId2);
      expect(await db.captureDao.getSuggestedCategory('SWIGGY'), catId2);
    });

    test('hasMatchingLoggedTransaction detects existing transactions within 24 hours', () async {
      final categories = await db.categoryDao.getAllCategories();
      final catId = categories.first.id;
      final now = DateTime.now();

      // Initially no match
      expect(
        await db.captureDao.hasMatchingLoggedTransaction(
          amountCents: 5000,
          date: now,
        ),
        isFalse,
      );

      // Insert transaction of 5000 cents at now
      await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          amount: 5000,
          type: TransactionType.expense,
          categoryId: catId,
          date: now,
        ),
      );

      // Exactly matches
      expect(
        await db.captureDao.hasMatchingLoggedTransaction(
          amountCents: 5000,
          date: now,
        ),
        isTrue,
      );

      // Matches within 24 hours (e.g. 12 hours later)
      expect(
        await db.captureDao.hasMatchingLoggedTransaction(
          amountCents: 5000,
          date: now.add(const Duration(hours: 12)),
        ),
        isTrue,
      );

      // Does NOT match different amount
      expect(
        await db.captureDao.hasMatchingLoggedTransaction(
          amountCents: 6000,
          date: now,
        ),
        isFalse,
      );

      // Does NOT match outside 24 hour window (e.g. 25 hours later)
      expect(
        await db.captureDao.hasMatchingLoggedTransaction(
          amountCents: 5000,
          date: now.add(const Duration(hours: 25)),
        ),
        isFalse,
      );
    });
  });
}
