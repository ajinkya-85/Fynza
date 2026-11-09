import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/app_database.dart';
import '../../features/budget/data/services/budget_dao.dart';
import '../../features/budget/domain/repositories/budget_repository.dart';
import '../../features/categories/data/services/category_dao.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/transactions/data/services/transaction_dao.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  return ref.watch(databaseProvider).categoryDao;
});

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return ref.watch(databaseProvider).transactionDao;
});

final budgetDaoProvider = Provider<BudgetDao>((ref) {
  return ref.watch(databaseProvider).budgetDao;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(categoryDaoProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.watch(transactionDaoProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(ref.watch(budgetDaoProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(transactionRepositoryProvider));
});
