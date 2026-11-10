import '../../../../shared/models/category_spending.dart';
import '../../../../shared/models/transaction_with_category.dart';

class DashboardSummary {
  final int totalIncomeCents;
  final int totalExpenseCents;
  final int netBalanceCents;
  final List<TransactionWithCategory> recentTransactions;
  final List<CategorySpending> categorySpendings;

  const DashboardSummary({
    required this.totalIncomeCents,
    required this.totalExpenseCents,
    required this.netBalanceCents,
    required this.recentTransactions,
    required this.categorySpendings,
  });

  const DashboardSummary.empty()
    : totalIncomeCents = 0,
      totalExpenseCents = 0,
      netBalanceCents = 0,
      recentTransactions = const [],
      categorySpendings = const [];
}

abstract class DashboardRepository {
  Stream<DashboardSummary> watchDashboardSummary({
    required int month,
    required int year,
  });
}
