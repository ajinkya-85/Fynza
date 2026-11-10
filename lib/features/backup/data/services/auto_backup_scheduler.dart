import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/constants/capture_constants.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../data/db/app_database.dart';
import '../../../auto_capture/data/services/auto_capture_scheduler.dart';
import '../../../auto_capture/data/services/capture_preferences_service.dart';
import '../../../auto_capture/data/services/notification_capture_service.dart';
import '../../../auto_capture/data/repositories/capture_repository_impl.dart';

import '../repositories/backup_repository_impl.dart';
import '../../domain/models/auto_backup_frequency.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/services/backup_services.dart';
import 'backup_file_service.dart';
import 'backup_preferences_service.dart';

const String autoBackupTaskName = 'expense_tracker_auto_backup';
const String autoBackupTaskType = 'auto_backup_periodic';

/// Pure function to determine whether an automatic backup should run.
bool shouldRunAutoBackup(
  DateTime now,
  DateTime? lastAutoBackupAt,
  AutoBackupFrequency frequency,
) {
  if (frequency == AutoBackupFrequency.off) return false;
  if (lastAutoBackupAt == null) return true;

  // Handle clock skew / backward clock
  if (now.isBefore(lastAutoBackupAt)) return true;

  final hoursPassed = now.difference(lastAutoBackupAt).inHours;
  return hoursPassed >= frequency.hours;
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();

      if (taskName == autoCaptureTaskType) {
        final capturePrefs = CapturePreferencesService(prefs);
        if (!CaptureConstants.isEnabled || !capturePrefs.isMasterEnabled()) {
          return true;
        }

        final db = AppDatabase();
        try {
          final captureService = NotificationCaptureServiceImpl();
          final captureRepo = CaptureRepositoryImpl(
            db: db,
            prefs: capturePrefs,
          );
          final notifications = await captureService.drain();
          if (notifications.isNotEmpty) {
            await captureRepo.ingest(notifications);
          }
        } finally {
          await db.close();
        }
        return true;
      }

      if (taskName != autoBackupTaskType) return false;

      final prefService = BackupPreferencesService(prefs);
      final currencyService = CurrencyService(prefs);

      final db = AppDatabase();
      final fileService = BackupFileService();
      final repo = BackupRepositoryImpl(
        db,
        currencyService,
        fileService: fileService,
      );

      try {
        await repo.createAutoBackup();
        await prefService.setLastAutoBackupAt(DateTime.now().toUtc());
      } finally {
        await db.close();
      }
      return true;
    } catch (error) {
      debugPrint('Background task failed: ${error.runtimeType}');
      return false;
    }
  });
}

class AutoBackupScheduler implements BackupScheduleController {
  final Workmanager _workmanager;
  final BackupPreferencesService _prefsService;

  AutoBackupScheduler(this._prefsService, {Workmanager? workmanager})
    : _workmanager = workmanager ?? Workmanager();

  /// Initializes workmanager on app launch.
  Future<void> initialize() async {
    try {
      await _workmanager.initialize(callbackDispatcher);
    } catch (error) {
      debugPrint('Workmanager initialization failed: ${error.runtimeType}');
    }
  }

  /// Updates the periodic work schedule when frequency is changed.
  @override
  Future<void> updateSchedule(AutoBackupFrequency frequency) async {
    await _prefsService.setFrequency(frequency);

    try {
      if (frequency == AutoBackupFrequency.off) {
        await _workmanager
            .cancelByUniqueName(autoBackupTaskName)
            .timeout(const Duration(milliseconds: 500));
      } else {
        await _workmanager
            .registerPeriodicTask(
              autoBackupTaskName,
              autoBackupTaskType,
              frequency: Duration(hours: frequency.hours),
              existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
              constraints: Constraints(networkType: NetworkType.notRequired),
            )
            .timeout(const Duration(milliseconds: 500));
      }
    } catch (_) {}
  }

  /// Runs a catch-up automatic backup on app launch if the interval has passed.
  Future<void> runLaunchCatchUp(BackupRepository repository) async {
    final frequency = _prefsService.getFrequency();
    final lastRun = _prefsService.getLastAutoBackupAt();
    final now = DateTime.now();

    if (shouldRunAutoBackup(now, lastRun, frequency)) {
      try {
        await repository.createAutoBackup();
        await _prefsService.setLastAutoBackupAt(now.toUtc());
      } catch (_) {}
    }
  }
}
