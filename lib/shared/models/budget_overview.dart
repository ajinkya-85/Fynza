import '../../features/budget/domain/models/budget.dart';
import '../../features/categories/domain/models/category.dart';

class BudgetOverview {
  final Budget budget;
  final Category category;
  final int spentCents;

  const BudgetOverview({
    required this.budget,
    required this.category,
    required this.spentCents,
  });

  double get progress {
    if (budget.amountLimit <= 0) return 0.0;
    return (spentCents / budget.amountLimit).clamp(0.0, 1.0);
  }

  bool get isOverBudget => spentCents > budget.amountLimit;

  int get remainingCents => budget.amountLimit - spentCents;
}
