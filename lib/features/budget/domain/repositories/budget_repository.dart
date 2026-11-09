import 'package:drift/drift.dart';
import '../../../../data/db/app_database.dart';
import '../../../../shared/models/budget_overview.dart';
import '../../data/services/budget_dao.dart';

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

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetDao _dao;

  BudgetRepositoryImpl(this._dao);

  @override
  Stream<List<BudgetOverview>> watchBudgetOverviews({
    required int month,
    required int year,
  }) {
    return _dao.watchBudgetOverviews(month: month, year: year);
  }

  @override
  Future<Budget?> getBudgetForCategory({
    required int categoryId,
    required int month,
    required int year,
  }) {
    return _dao.getBudgetForCategory(categoryId, month, year);
  }

  @override
  Future<int> setBudget({
    required int categoryId,
    required int amountLimitCents,
    required int month,
    required int year,
  }) {
    return _dao.setBudget(
      BudgetsCompanion(
        categoryId: Value(categoryId),
        amountLimit: Value(amountLimitCents),
        month: Value(month),
        year: Value(year),
      ),
    );
  }

  @override
  Future<int> deleteBudget(int id) {
    return _dao.deleteBudget(id);
  }
}
