import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fynza/data/db/app_database.dart';
import 'package:fynza/shared/models/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('BudgetDao tests', () {
    test('Set budget and watch budget overviews with calculated spend', () async {
      final categories = await db.categoryDao.getAllCategories();
      final groceries = categories.firstWhere((c) => c.name == 'Groceries');

      final now = DateTime.now();
      // Set budget of $150 (15000 cents) for Groceries for this month
      await db.budgetDao.setBudget(
        BudgetsCompanion(
          categoryId: Value(groceries.id),
          amountLimit: const Value(15000),
          month: Value(now.month),
          year: Value(now.year),
        ),
      );

      // Add transaction of $45 (4500 cents)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amount: 4500,
          type: TransactionType.expense,
          categoryId: groceries.id,
          date: now,
        ),
      );

      final overviews = await db.budgetDao
          .watchBudgetOverviews(month: now.month, year: now.year)
          .first;

      expect(overviews.length, 1);
      final budget = overviews.first;
      expect(budget.category.name, 'Groceries');
      expect(budget.budget.amountLimit, 15000);
      expect(budget.spentCents, 4500);
      expect(budget.remainingCents, 10500);
      expect(budget.isOverBudget, isFalse);
      expect(budget.progress, closeTo(0.3, 0.01));
    });

    test('Detects over-budget situation', () async {
      final categories = await db.categoryDao.getAllCategories();
      final food = categories.firstWhere((c) => c.name == 'Food & Dining');

      final now = DateTime.now();
      // Budget: $50
      await db.budgetDao.setBudget(
        BudgetsCompanion(
          categoryId: Value(food.id),
          amountLimit: const Value(5000),
          month: Value(now.month),
          year: Value(now.year),
        ),
      );

      // Spent: $80
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amount: 8000,
          type: TransactionType.expense,
          categoryId: food.id,
          date: now,
        ),
      );

      final overviews = await db.budgetDao
          .watchBudgetOverviews(month: now.month, year: now.year)
          .first;

      final budget = overviews.first;
      expect(budget.spentCents, 8000);
      expect(budget.isOverBudget, isTrue);
      expect(budget.remainingCents, -3000);
      expect(budget.progress, 1.0);
    });
  });
}
