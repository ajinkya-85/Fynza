import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:expense_tracker/data/db/app_database.dart';
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

  group('TransactionDao tests', () {
    test('Insert transaction and watch with category join', () async {
      final categories = await db.categoryDao.getAllCategories();
      final foodCategory =
          categories.firstWhere((c) => c.name == 'Food & Dining');

      final now = DateTime.now();
      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amount: 2550, // $25.50
          type: TransactionType.expense,
          categoryId: foodCategory.id,
          date: now,
          note: const Value('Lunch burger'),
        ),
      );

      final fetched = await db.transactionDao.getTransactionWithCategory(id);
      expect(fetched, isNotNull);
      expect(fetched!.transaction.amount, 2550);
      expect(fetched.transaction.note, 'Lunch burger');
      expect(fetched.category.name, 'Food & Dining');
    });

    test('Watch total amounts filters correctly by type', () async {
      final categories = await db.categoryDao.getAllCategories();
      final foodCat = categories.firstWhere((c) => c.name == 'Food & Dining');
      final salaryCat = categories.firstWhere((c) => c.name == 'Salary');

      final now = DateTime.now();
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amount: 1500, // $15.00 expense
          type: TransactionType.expense,
          categoryId: foodCat.id,
          date: now,
        ),
      );
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amount: 3500, // $35.00 expense
          type: TransactionType.expense,
          categoryId: foodCat.id,
          date: now,
        ),
      );
      await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amount: 200000, // $2000.00 income
          type: TransactionType.income,
          categoryId: salaryCat.id,
          date: now,
        ),
      );

      final totalExpense =
          await db.transactionDao.watchTotalAmount(type: TransactionType.expense).first;
      expect(totalExpense, 5000); // 5000 cents = $50.00

      final totalIncome =
          await db.transactionDao.watchTotalAmount(type: TransactionType.income).first;
      expect(totalIncome, 200000); // 200000 cents = $2000.00
    });

    test('Delete transaction cascades or removes record', () async {
      final categories = await db.categoryDao.getAllCategories();
      final cat = categories.first;

      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amount: 1000,
          type: TransactionType.expense,
          categoryId: cat.id,
          date: DateTime.now(),
        ),
      );

      final count = await db.transactionDao.deleteTransaction(id);
      expect(count, 1);

      final item = await db.transactionDao.getTransactionWithCategory(id);
      expect(item, isNull);
    });
  });
}
