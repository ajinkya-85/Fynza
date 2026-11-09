import 'package:drift/drift.dart';
import '../../../../data/db/app_database.dart';
import '../../../../shared/models/category_spending.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/models/transaction_with_category.dart';
import '../../data/services/transaction_dao.dart';

abstract class TransactionRepository {
  Stream<List<TransactionWithCategory>> watchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    TransactionType? type,
  });

  Stream<List<TransactionWithCategory>> watchRecentTransactions({int limit = 5});

  Future<TransactionWithCategory?> getTransaction(int id);

  Future<int> addTransaction({
    required int amountCents,
    required TransactionType type,
    required int categoryId,
    required DateTime date,
    String? note,
  });

  Future<bool> updateTransaction({
    required int id,
    required int amountCents,
    required TransactionType type,
    required int categoryId,
    required DateTime date,
    String? note,
  });

  Future<int> deleteTransaction(int id);

  Stream<int> watchTotal({
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<List<CategorySpending>> watchCategorySpending({
    required DateTime startDate,
    required DateTime endDate,
  });
}

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDao _dao;

  TransactionRepositoryImpl(this._dao);

  @override
  Stream<List<TransactionWithCategory>> watchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    TransactionType? type,
  }) {
    return _dao.watchTransactionsWithCategory(
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      type: type,
    );
  }

  @override
  Stream<List<TransactionWithCategory>> watchRecentTransactions({int limit = 5}) {
    return _dao.watchRecentTransactions(limit: limit);
  }

  @override
  Future<TransactionWithCategory?> getTransaction(int id) {
    return _dao.getTransactionWithCategory(id);
  }

  @override
  Future<int> addTransaction({
    required int amountCents,
    required TransactionType type,
    required int categoryId,
    required DateTime date,
    String? note,
  }) {
    return _dao.insertTransaction(
      TransactionsCompanion.insert(
        amount: amountCents,
        type: type,
        categoryId: categoryId,
        date: date,
        note: Value(note),
      ),
    );
  }

  @override
  Future<bool> updateTransaction({
    required int id,
    required int amountCents,
    required TransactionType type,
    required int categoryId,
    required DateTime date,
    String? note,
  }) {
    return _dao.updateTransaction(
      TransactionsCompanion(
        id: Value(id),
        amount: Value(amountCents),
        type: Value(type),
        categoryId: Value(categoryId),
        date: Value(date),
        note: Value(note),
      ),
    );
  }

  @override
  Future<int> deleteTransaction(int id) {
    return _dao.deleteTransaction(id);
  }

  @override
  Stream<int> watchTotal({
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dao.watchTotalAmount(
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Stream<List<CategorySpending>> watchCategorySpending({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _dao.watchCategorySpending(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
