import '../constants/capture_constants.dart';
import '../../features/auto_capture/data/services/auto_capture_scheduler.dart';
import '../../features/backup/data/services/auto_backup_scheduler.dart';
import '../../features/backup/domain/repositories/backup_repository.dart';

class AppStartupCoordinator {
  final AutoBackupScheduler _backupScheduler;
  final BackupRepository _backupRepository;
  final AutoCaptureScheduler _captureScheduler;

  const AppStartupCoordinator({
    required this._backupScheduler,
    required this._backupRepository,
    required this._captureScheduler,
  });

  Future<void> runLaunchTasks({required bool autoCaptureEnabled}) async {
    await _backupScheduler.runLaunchCatchUp(_backupRepository);
    if (CaptureConstants.isEnabled && autoCaptureEnabled) {
      await _captureScheduler.drainNow();
    }
  }
}
