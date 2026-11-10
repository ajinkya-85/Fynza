import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auto_capture/data/repositories/capture_repository_impl.dart';
import '../../features/auto_capture/data/services/capture_preferences_service.dart';
import '../../features/auto_capture/data/services/notification_capture_service.dart';
import '../../features/auto_capture/data/services/auto_capture_scheduler.dart';
import '../../features/auto_capture/domain/repositories/capture_repository.dart';
import '../../features/backup/data/services/auto_backup_scheduler.dart';
import '../../features/backup/data/services/backup_preferences_service.dart';
import '../../features/backup/data/services/backup_file_service.dart';
import '../../data/db/app_database.dart';
import '../../features/budget/data/services/budget_dao.dart';
import '../../features/budget/data/repositories/budget_repository_impl.dart';
import '../../features/budget/domain/repositories/budget_repository.dart';
import '../../features/backup/data/repositories/backup_repository_impl.dart';
import '../../features/backup/domain/repositories/backup_repository.dart';
import '../services/currency_service.dart';
import '../services/app_startup_coordinator.dart';
import '../../features/categories/data/services/category_dao.dart';
import '../../features/categories/data/repositories/category_repository_impl.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/transactions/data/services/transaction_dao.dart';
import '../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final captureRepositoryProvider = Provider<CaptureRepository>((ref) {
  return CaptureRepositoryImpl(
    db: ref.watch(databaseProvider),
    prefs: ref.watch(capturePreferencesServiceProvider),
  );
});

final capturePreferencesServiceProvider = Provider<CapturePreferencesService>((
  ref,
) {
  return CapturePreferencesService(ref.watch(sharedPreferencesProvider));
});

final autoCaptureEnabledProvider =
    StateNotifierProvider<AutoCaptureEnabledNotifier, bool>((ref) {
      return AutoCaptureEnabledNotifier(
        ref.watch(capturePreferencesServiceProvider),
      );
    });

final notificationCaptureServiceProvider = Provider<NotificationCaptureService>(
  (ref) {
    return NotificationCaptureServiceImpl();
  },
);

final autoCaptureSchedulerProvider = Provider<AutoCaptureScheduler>((ref) {
  return AutoCaptureScheduler(
    ref.watch(notificationCaptureServiceProvider),
    ref.watch(captureRepositoryProvider),
    preferences: ref.watch(capturePreferencesServiceProvider),
  );
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepositoryImpl(
    ref.watch(databaseProvider),
    ref.watch(currencyServiceProvider),
  );
});

final backupPreferencesServiceProvider = Provider<BackupPreferencesService>((
  ref,
) {
  return BackupPreferencesService(ref.watch(sharedPreferencesProvider));
});

final autoBackupSchedulerProvider = Provider<AutoBackupScheduler>((ref) {
  return AutoBackupScheduler(ref.watch(backupPreferencesServiceProvider));
});

final backupFileServiceProvider = Provider<BackupFileService>((ref) {
  return BackupFileService();
});

final appStartupCoordinatorProvider = Provider<AppStartupCoordinator>((ref) {
  return AppStartupCoordinator(
    backupScheduler: ref.watch(autoBackupSchedulerProvider),
    backupRepository: ref.watch(backupRepositoryProvider),
    captureScheduler: ref.watch(autoCaptureSchedulerProvider),
  );
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
