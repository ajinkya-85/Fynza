import 'package:drift/drift.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/db/tables/budgets_table.dart';
import '../../../../data/db/tables/categories_table.dart';
import '../../../../data/db/tables/transactions_table.dart';
import '../../../../shared/models/budget_overview.dart';
import '../../../../shared/models/transaction_type.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets, Categories, Transactions])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.attachedDatabase);

  Stream<List<BudgetOverview>> watchBudgetOverviews({
    required int month,
    required int year,
  }) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);

    final spentSum = transactions.amount.sum();

    final query = select(budgets).join([
      innerJoin(categories, categories.id.equalsExp(budgets.categoryId)),
      leftOuterJoin(
        transactions,
        transactions.categoryId.equalsExp(budgets.categoryId) &
            transactions.type.equals(TransactionType.expense.name) &
            transactions.date.isBiggerOrEqualValue(startDate) &
            transactions.date.isSmallerOrEqualValue(endDate),
      ),
    ])
      ..where(budgets.month.equals(month) & budgets.year.equals(year))
      ..groupBy([budgets.id, categories.id])
      ..addColumns([spentSum])
      ..orderBy([OrderingTerm.asc(categories.name)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return BudgetOverview(
          budget: row.readTable(budgets),
          category: row.readTable(categories),
          spentCents: row.read(spentSum) ?? 0,
        );
      }).toList();
    });
  }

  Future<Budget?> getBudgetForCategory(int categoryId, int month, int year) {
    return (select(budgets)
          ..where((t) =>
              t.categoryId.equals(categoryId) &
              t.month.equals(month) &
              t.year.equals(year)))
        .getSingleOrNull();
  }

  Future<int> setBudget(BudgetsCompanion companion) {
    return into(budgets).insertOnConflictUpdate(companion);
  }

  Future<int> deleteBudget(int id) {
    return (delete(budgets)..where((t) => t.id.equals(id))).go();
  }
}
