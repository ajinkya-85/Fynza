import '../../data/db/app_database.dart';

class CategorySpending {
  final Category category;
  final int totalCents;
  final int transactionCount;

  const CategorySpending({
    required this.category,
    required this.totalCents,
    required this.transactionCount,
  });
}
