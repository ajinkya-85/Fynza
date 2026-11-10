import 'dart:async';
import 'package:fynza/features/budget/domain/models/budget.dart';
import 'package:fynza/features/categories/domain/models/category.dart';
import 'package:fynza/features/budget/domain/repositories/budget_repository.dart';
import 'package:fynza/features/budget/presentation/view_models/budget_notifier.dart';
import 'package:fynza/shared/models/budget_overview.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBudgetRepository implements BudgetRepository {
  final List<BudgetOverview> items = [];
  final StreamController<List<BudgetOverview>> _controller =
      StreamController<List<BudgetOverview>>.broadcast();

  void emit() {
    _controller.add(List.unmodifiable(items));
  }

  @override
  Stream<List<BudgetOverview>> watchBudgetOverviews({
    required int month,
    required int year,
  }) {
    return _controller.stream;
  }

  @override
  Future<Budget?> getBudgetForCategory({
    required int categoryId,
    required int month,
    required int year,
  }) async {
    return items
        .where(
          (b) =>
              b.budget.categoryId == categoryId &&
              b.budget.month == month &&
              b.budget.year == year,
        )
        .map((b) => b.budget)
        .firstOrNull;
  }

  @override
  Future<int> setBudget({
    required int categoryId,
    required int amountLimitCents,
    required int month,
    required int year,
  }) async {
    items.removeWhere(
      (b) =>
          b.budget.categoryId == categoryId &&
          b.budget.month == month &&
          b.budget.year == year,
    );

    final b = BudgetOverview(
      budget: Budget(
        id: items.length + 1,
        categoryId: categoryId,
        amountLimit: amountLimitCents,
        month: month,
        year: year,
      ),
      category: Category(
        id: categoryId,
        name: 'Category $categoryId',
        icon: 'restaurant',
        color: 0xFFE65100,
        isIncome: false,
      ),
      spentCents: 0,
    );
    items.add(b);
    emit();
    return b.budget.id;
  }

  @override
  Future<int> deleteBudget(int id) async {
    items.removeWhere((b) => b.budget.id == id);
    emit();
    return 1;
  }
}

void main() {
  late FakeBudgetRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeBudgetRepository();
  });

  group('BudgetNotifier tests', () {
    test('Set budget updates repository and totals', () async {
      final notifier = BudgetNotifier(fakeRepo);

      await notifier.setBudget(
        categoryId: 1,
        amountLimitCents: 20000, // $200.00
      );

      await Future.delayed(Duration.zero);

      expect(notifier.state.overviews.length, 1);
      expect(notifier.state.totalBudgetedCents, 20000);
      expect(notifier.state.totalSpentCents, 0);

      notifier.dispose();
    });

    test('updates the displayed period when the shared month changes', () {
      final notifier = BudgetNotifier(fakeRepo);
      notifier.setMonth(12, 2026);

      expect(notifier.state.selectedMonth, 12);
      expect(notifier.state.selectedYear, 2026);

      notifier.dispose();
    });
  });
}
