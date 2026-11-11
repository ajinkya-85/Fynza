import 'package:drift/drift.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/db/tables/captured_transactions_table.dart';
import '../../../../data/db/tables/counterparty_rules_table.dart';
import '../../domain/models/capture_status.dart';
import '../../../../shared/models/transaction_type.dart';

part 'capture_dao.g.dart';

@DriftAccessor(tables: [CapturedTransactions, CounterpartyRules])
class CaptureDao extends DatabaseAccessor<AppDatabase> with _$CaptureDaoMixin {
  CaptureDao(super.db);

  /// Watches all pending captured transactions ordered newest first.
  Stream<List<CapturedTransaction>> watchPendingCaptures() {
    return (select(capturedTransactions)
          ..where((t) => t.status.equals(CaptureStatus.pending.name))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Watches count of pending captured transactions.
  Stream<int> watchPendingCount() {
    final countExp = capturedTransactions.id.count();
    final query = selectOnly(capturedTransactions)
      ..where(capturedTransactions.status.equals(CaptureStatus.pending.name))
      ..addColumns([countExp]);

    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// Watches recently auto-added / confirmed transactions.
  Stream<List<CapturedTransaction>> watchRecentlyAutoAdded({int limit = 10}) {
    return (select(capturedTransactions)
          ..where(
            (t) =>
                t.status.equals(CaptureStatus.confirmed.name) &
                t.transactionId.isNotNull(),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.capturedAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  /// Inserts a captured transaction row with insert-or-ignore (dedupe via UNIQUE constraint).
  Future<int> insertCaptureOrIgnore(CapturedTransactionsCompanion entry) {
    return into(
      capturedTransactions,
    ).insert(entry, mode: InsertMode.insertOrIgnore);
  }

  /// Inserts a capture row and fails on a duplicate dedupe key.
  Future<int> insertCapture(CapturedTransactionsCompanion entry) {
    return into(capturedTransactions).insert(entry);
  }

  /// Finds an existing capture by its stable deduplication key.
  Future<CapturedTransaction?> getCaptureByDedupeKey(String dedupeKey) {
    return (select(
      capturedTransactions,
    )..where((t) => t.dedupeKey.equals(dedupeKey))).getSingleOrNull();
  }

  /// Matches a transaction reference across captures created by older app
  /// versions, whose dedupe keys were not scoped to amount/type/account.
  Future<CapturedTransaction?> findMatchingCaptureIdentity({
    required String reference,
    required int amountCents,
    required TransactionType type,
    String? accountLast4,
  }) async {
    final matches =
        await (select(capturedTransactions)..where(
              (t) =>
                  t.reference.equals(reference) &
                  t.amountCents.equals(amountCents) &
                  t.type.equals(type.name),
            ))
            .get();
    final compatibleMatches = matches
        .where(
          (capture) =>
              capture.accountLast4 == null ||
              accountLast4 == null ||
              capture.accountLast4 == accountLast4,
        )
        .toList();
    compatibleMatches.sort((a, b) {
      final aPending = a.status == CaptureStatus.pending;
      final bPending = b.status == CaptureStatus.pending;
      if (aPending == bPending) return 0;
      return aPending ? -1 : 1;
    });
    return compatibleMatches.isEmpty ? null : compatibleMatches.first;
  }

  /// Atomically counts another notification matching the same transaction.
  Future<void> incrementDuplicateCount(int captureId) {
    return customStatement(
      'UPDATE captured_transactions '
      'SET duplicate_count = duplicate_count + 1 WHERE id = ?',
      [captureId],
    );
  }

  /// Finds a captured transaction by ID.
  Future<CapturedTransaction?> getCaptureById(int id) {
    return (select(
      capturedTransactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Updates status of a captured transaction.
  Future<int> updateCaptureStatus(
    int id,
    CaptureStatus status, {
    int? transactionId,
  }) {
    return (update(capturedTransactions)..where((t) => t.id.equals(id))).write(
      CapturedTransactionsCompanion(
        status: Value(status),
        transactionId: Value(transactionId),
      ),
    );
  }

  /// Gets all captured transactions (e.g. for backup).
  Future<List<CapturedTransaction>> getAllCaptures() {
    return select(capturedTransactions).get();
  }

  /// Inserts multiple captured transactions (used during backup restore).
  Future<void> insertAllCaptures(List<CapturedTransactionsCompanion> rows) {
    return batch((b) {
      b.insertAll(capturedTransactions, rows, mode: InsertMode.insertOrReplace);
    });
  }

  /// Dismisses all pending items from a specific sender.
  Future<int> dismissPendingBySender(String sender) {
    return (update(capturedTransactions)..where(
          (t) =>
              t.sender.equals(sender) &
              t.status.equals(CaptureStatus.pending.name),
        ))
        .write(
          const CapturedTransactionsCompanion(
            status: Value(CaptureStatus.dismissed),
          ),
        );
  }

  /// Deletes all captured transactions.
  Future<int> deleteAllCaptures() {
    return delete(capturedTransactions).go();
  }

  /// Purges confirmed and dismissed captures older than 90 days.
  Future<int> purgeOldCaptures(DateTime olderThan) {
    return (delete(capturedTransactions)..where(
          (t) =>
              (t.status.equals(CaptureStatus.confirmed.name) |
                  t.status.equals(CaptureStatus.dismissed.name)) &
              t.capturedAt.isSmallerThanValue(olderThan),
        ))
        .go();
  }

  // Counterparty rule queries

  /// Looks up suggested category for normalized counterparty.
  Future<int?> getSuggestedCategory(String normalizedCounterparty) async {
    final rule =
        await (select(counterpartyRules)..where(
              (t) => t.normalizedCounterparty.equals(normalizedCounterparty),
            ))
            .getSingleOrNull();
    return rule?.categoryId;
  }

  /// Upserts suggested category for a normalized counterparty.
  Future<void> setSuggestedCategory(
    String normalizedCounterparty,
    int categoryId,
  ) async {
    await into(counterpartyRules).insert(
      CounterpartyRulesCompanion.insert(
        normalizedCounterparty: normalizedCounterparty,
        categoryId: categoryId,
        updatedAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
}
