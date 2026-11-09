import '../../data/db/app_database.dart';

class TransactionWithCategory {
  final Transaction transaction;
  final Category category;

  const TransactionWithCategory({
    required this.transaction,
    required this.category,
  });
}
