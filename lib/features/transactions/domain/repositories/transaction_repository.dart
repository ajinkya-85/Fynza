import '../../../../shared/models/category_spending.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/models/transaction_with_category.dart';

abstract class TransactionRepository {
  Stream<List<TransactionWithCategory>> watchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    TransactionType? type,
  });

  Stream<List<TransactionWithCategory>> watchRecentTransactions({
    int limit = 5,
  });

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
