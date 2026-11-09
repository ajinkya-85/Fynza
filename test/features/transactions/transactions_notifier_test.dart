import 'dart:async';
import 'package:expense_tracker/data/db/app_database.dart';
import 'package:expense_tracker/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/presentation/view_models/transaction_form_notifier.dart';
import 'package:expense_tracker/features/transactions/presentation/view_models/transactions_notifier.dart';
import 'package:expense_tracker/shared/models/category_spending.dart';
import 'package:expense_tracker/shared/models/transaction_type.dart';
import 'package:expense_tracker/shared/models/transaction_with_category.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionWithCategory> items = [];
  final StreamController<List<TransactionWithCategory>> _controller =
      StreamController<List<TransactionWithCategory>>.broadcast();

  void emit() {
    _controller.add(List.unmodifiable(items));
  }

  @override
  Stream<List<TransactionWithCategory>> watchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    TransactionType? type,
  }) {
    return _controller.stream;
  }

  @override
  Stream<List<TransactionWithCategory>> watchRecentTransactions({int limit = 5}) {
    return _controller.stream;
  }

  @override
  Future<TransactionWithCategory?> getTransaction(int id) async {
    return items.cast<TransactionWithCategory?>().firstWhere(
          (t) => t?.transaction.id == id,
          orElse: () => null,
        );
  }

  @override
  Future<int> addTransaction({
    required int amountCents,
    required TransactionType type,
    required int categoryId,
    required DateTime date,
    String? note,
  }) async {
    final t = TransactionWithCategory(
      transaction: Transaction(
        id: items.length + 1,
        amount: amountCents,
        type: type,
        categoryId: categoryId,
        date: date,
        note: note,
        createdAt: DateTime.now(),
      ),
      category: Category(
        id: categoryId,
        name: 'Test Category',
        icon: 'restaurant',
        color: 0xFFE65100,
        isIncome: type == TransactionType.income,
      ),
    );
    items.add(t);
    emit();
    return t.transaction.id;
  }

  @override
  Future<bool> updateTransaction({
    required int id,
    required int amountCents,
    required TransactionType type,
    required int categoryId,
    required DateTime date,
    String? note,
  }) async {
    final index = items.indexWhere((t) => t.transaction.id == id);
    if (index == -1) return false;
    items[index] = TransactionWithCategory(
      transaction: Transaction(
        id: id,
        amount: amountCents,
        type: type,
        categoryId: categoryId,
        date: date,
        note: note,
        createdAt: DateTime.now(),
      ),
      category: items[index].category,
    );
    emit();
    return true;
  }

  @override
  Future<int> deleteTransaction(int id) async {
    items.removeWhere((t) => t.transaction.id == id);
    emit();
    return 1;
  }

  @override
  Stream<int> watchTotal({
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Stream.value(0);
  }

  @override
  Stream<List<CategorySpending>> watchCategorySpending({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return Stream.value([]);
  }
}

void main() {
  late FakeTransactionRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeTransactionRepository();
  });

  group('TransactionsNotifier tests', () {
    test('Filter by type updates state and filteredTransactions', () async {
      final notifier = TransactionsNotifier(fakeRepo);

      // Add one expense and one income
      await fakeRepo.addTransaction(
        amountCents: 1500,
        type: TransactionType.expense,
        categoryId: 1,
        date: DateTime.now(),
      );
      await fakeRepo.addTransaction(
        amountCents: 50000,
        type: TransactionType.income,
        categoryId: 2,
        date: DateTime.now(),
      );

      // Wait a tick for stream
      await Future.delayed(Duration.zero);

      expect(notifier.state.transactions.length, 2);

      // Filter only Expense
      notifier.setTypeFilter(TransactionType.expense);
      expect(notifier.state.typeFilter, TransactionType.expense);
      expect(notifier.state.filteredTransactions.length, 1);
      expect(
        notifier.state.filteredTransactions.first.transaction.type,
        TransactionType.expense,
      );

      // Clear filter
      notifier.setTypeFilter(null);
      expect(notifier.state.typeFilter, isNull);
      expect(notifier.state.filteredTransactions.length, 2);

      notifier.dispose();
    });

    test('updates the displayed period when the shared month changes', () {
      final notifier = TransactionsNotifier(fakeRepo);
      notifier.setMonth(DateTime(2026, 12));

      expect(notifier.state.selectedMonth, DateTime(2026, 12));

      notifier.dispose();
    });
  });

  group('TransactionFormNotifier tests', () {
    test('Rejects save when amount is 0', () async {
      final notifier = TransactionFormNotifier(fakeRepo);
      notifier.setCategory(1);

      final success = await notifier.save();
      expect(success, isFalse);
      expect(notifier.state.errorMessage, contains('greater than 0'));
    });

    test('Rejects save when category is null', () async {
      final notifier = TransactionFormNotifier(fakeRepo);
      notifier.setAmount(2000);

      final success = await notifier.save();
      expect(success, isFalse);
      expect(notifier.state.errorMessage, contains('select a category'));
    });

    test('Successfully saves transaction with valid inputs', () async {
      final notifier = TransactionFormNotifier(fakeRepo);
      notifier.setAmount(3550);
      notifier.setCategory(1);
      notifier.setType(TransactionType.expense);
      notifier.setNote('Coffee with friend');

      final success = await notifier.save();
      expect(success, isTrue);
      expect(notifier.state.isSuccess, isTrue);
      expect(fakeRepo.items.length, 1);
      expect(fakeRepo.items.first.transaction.amount, 3550);
      expect(fakeRepo.items.first.transaction.note, 'Coffee with friend');
    });
  });
}
