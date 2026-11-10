import 'package:drift/drift.dart';

import '../../../../data/db/app_database.dart' as db;
import '../../../../shared/models/budget_overview.dart';
import '../../domain/models/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../services/budget_dao.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetDao _dao;

  BudgetRepositoryImpl(this._dao);

  Budget _toDomain(db.Budget value) => Budget(
    id: value.id,
    categoryId: value.categoryId,
    amountLimit: value.amountLimit,
    month: value.month,
    year: value.year,
  );

  @override
  Stream<List<BudgetOverview>> watchBudgetOverviews({
    required int month,
    required int year,
  }) => _dao.watchBudgetOverviews(month: month, year: year);

  @override
  Future<Budget?> getBudgetForCategory({
    required int categoryId,
    required int month,
    required int year,
  }) async {
    final value = await _dao.getBudgetForCategory(categoryId, month, year);
    return value == null ? null : _toDomain(value);
  }

  @override
  Future<int> setBudget({
    required int categoryId,
    required int amountLimitCents,
    required int month,
    required int year,
  }) => _dao.setBudget(
    db.BudgetsCompanion(
      categoryId: Value(categoryId),
      amountLimit: Value(amountLimitCents),
      month: Value(month),
      year: Value(year),
    ),
  );

  @override
  Future<int> deleteBudget(int id) => _dao.deleteBudget(id);
}
