import '../../features/categories/domain/models/category.dart';
import '../../features/transactions/domain/models/transaction.dart';

class TransactionWithCategory {
  final Transaction transaction;
  final Category category;

  const TransactionWithCategory({
    required this.transaction,
    required this.category,
  });
}
