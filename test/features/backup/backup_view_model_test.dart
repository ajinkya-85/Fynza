import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fynza/features/backup/data/services/auto_backup_scheduler.dart';
import 'package:fynza/features/backup/data/services/backup_preferences_service.dart';
import 'package:fynza/features/backup/domain/models/auto_backup_frequency.dart';
import 'package:fynza/features/backup/domain/models/backup_file_info.dart';
import 'package:fynza/features/backup/domain/models/backup_failure.dart';
import 'package:fynza/features/backup/domain/models/backup_summary.dart';
import 'package:fynza/features/backup/domain/repositories/backup_repository.dart';
import 'package:fynza/features/backup/presentation/view_models/backup_view_model.dart';
import 'package:fynza/features/backup/domain/services/backup_services.dart';

class FakeBackupFileNameGenerator implements BackupFileNameGenerator {
  @override
  String generateManualFileName([DateTime? time]) => 'backup.expbak';
}

class FakeBackupRepository implements BackupRepository {
  bool shouldFailRestore = false;
  bool shouldFailCreate = false;

  @override
  Future<Uint8List> createBackupBytes({String appVersion = '1.0.0'}) async {
    if (shouldFailCreate) {
      throw const StorageErrorFailure('Disk full');
    }
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<BackupSummary> inspectBackup(Uint8List bytes) async {
    return BackupSummary(
      formatVersion: 1,
      appVersion: '1.0.0',
      dbSchemaVersion: 1,
      createdAt: DateTime.utc(2026, 10, 10),
      categoryCount: 5,
      transactionCount: 10,
      budgetCount: 2,
    );
  }

  @override
  Future<void> restoreBackup(Uint8List bytes) async {
    if (shouldFailRestore) {
      throw const CorruptDataFailure('Invalid data in backup');
    }
  }

  @override
  Future<void> createAutoBackup({String appVersion = '1.0.0'}) async {}

  @override
  Future<void> deleteBackupFile(String path) async {}

  @override
  Future<String> getBackupDirectoryPath() async => '/mock/backups';

  @override
  Future<({int fileCount, int totalSizeBytes})> getStorageUsage() async =>
      (fileCount: 2, totalSizeBytes: 2048);

  @override
  Future<List<BackupFileInfo>> listAutoBackups() async => [];
}

void main() {
  group('BackupViewModel Tests', () {
    late FakeBackupRepository fakeRepo;
    late BackupPreferencesService prefsService;
    late AutoBackupScheduler scheduler;
    late BackupViewModel viewModel;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      prefsService = BackupPreferencesService(prefs);
      fakeRepo = FakeBackupRepository();
      scheduler = AutoBackupScheduler(prefsService);

      viewModel = BackupViewModel(
        fakeRepo,
        prefsService,
        scheduler,
        fileNameGenerator: FakeBackupFileNameGenerator(),
      );
    });

    test('Loads initial state correctly', () async {
      await viewModel.loadState();
      expect(viewModel.state.backupDirectoryPath, '/mock/backups');
      expect(viewModel.state.frequency, AutoBackupFrequency.every12Hours);
      expect(viewModel.state.storageFileCount, 2);
      expect(viewModel.state.storageUsageBytes, 2048);
    });

    test('Updates frequency and persists in preferences', () async {
      await viewModel.setFrequency(AutoBackupFrequency.daily);
      expect(viewModel.state.frequency, AutoBackupFrequency.daily);
      expect(prefsService.getFrequency(), AutoBackupFrequency.daily);
    });

    test('Restores successfully and updates state', () async {
      final summary = await fakeRepo.inspectBackup(Uint8List(0));
      final success = await viewModel.restoreBackup(
        Uint8List.fromList([1, 2, 3]),
        summary: summary,
      );

      expect(success, isTrue);
      expect(
        viewModel.state.successMessage,
        contains('Restored 10 transactions'),
      );
      expect(viewModel.state.isBusy, isFalse);
    });

    test('Maps failures to friendly user message on restore error', () async {
      fakeRepo.shouldFailRestore = true;
      final summary = await fakeRepo.inspectBackup(Uint8List(0));
      final success = await viewModel.restoreBackup(
        Uint8List.fromList([1, 2, 3]),
        summary: summary,
      );

      expect(success, isFalse);
      expect(
        viewModel.state.userErrorMessage,
        contains('Backup data is invalid: Invalid data in backup'),
      );
      expect(viewModel.state.isBusy, isFalse);
    });
  });
}
