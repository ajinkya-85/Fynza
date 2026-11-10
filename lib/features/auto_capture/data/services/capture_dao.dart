import 'package:drift/drift.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/db/tables/captured_transactions_table.dart';
import '../../../../data/db/tables/counterparty_rules_table.dart';
import '../../domain/models/capture_status.dart';

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

  /// Checks whether a transaction with the same amount already exists in the transactions table
  /// within +/- 24 hours of the given date.
  Future<bool> hasMatchingLoggedTransaction({
    required int amountCents,
    required DateTime date,
  }) async {
    final start = date.subtract(const Duration(hours: 24));
    final end = date.add(const Duration(hours: 24));
    final query = db.select(db.transactions)
      ..where(
        (t) =>
            t.amount.equals(amountCents) &
            t.date.isBiggerOrEqualValue(start) &
            t.date.isSmallerOrEqualValue(end),
      )
      ..limit(1);
    final match = await query.getSingleOrNull();
    return match != null;
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
