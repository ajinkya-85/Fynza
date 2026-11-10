import '../../../../shared/models/budget_overview.dart';
import '../models/budget.dart';

abstract class BudgetRepository {
  Stream<List<BudgetOverview>> watchBudgetOverviews({
    required int month,
    required int year,
  });

  Future<Budget?> getBudgetForCategory({
    required int categoryId,
    required int month,
    required int year,
  });

  Future<int> setBudget({
    required int categoryId,
    required int amountLimitCents,
    required int month,
    required int year,
  });

  Future<int> deleteBudget(int id);
}
