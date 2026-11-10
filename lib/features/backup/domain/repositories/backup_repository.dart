import 'dart:typed_data';

import '../models/backup_file_info.dart';
import '../models/backup_summary.dart';

abstract class BackupRepository {
  Future<BackupSummary> inspectBackup(Uint8List bytes);
  Future<Uint8List> createBackupBytes({String appVersion = '1.0.0'});
  Future<void> createAutoBackup({String appVersion = '1.0.0'});
  Future<void> restoreBackup(Uint8List bytes);
  Future<List<BackupFileInfo>> listAutoBackups();
  Future<void> deleteBackupFile(String path);
  Future<({int fileCount, int totalSizeBytes})> getStorageUsage();
  Future<String> getBackupDirectoryPath();
}
