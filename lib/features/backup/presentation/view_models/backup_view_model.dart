import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/currency_service.dart';
import '../../data/services/auto_backup_scheduler.dart';
import '../../data/services/backup_file_service.dart';
import '../../data/services/backup_preferences_service.dart';
import '../../domain/models/auto_backup_frequency.dart';
import '../../domain/models/backup_failure.dart';
import '../../domain/models/backup_summary.dart';
import '../../domain/repositories/backup_repository.dart';

class BackupUiState {
  final bool isBusy;
  final String? busyStatus;
  final String backupDirectoryPath;
  final AutoBackupFrequency frequency;
  final DateTime? lastAutoBackupAt;
  final List<BackupFileInfo> autoBackups;
  final int storageUsageBytes;
  final int storageFileCount;
  final String? userErrorMessage;
  final String? successMessage;

  const BackupUiState({
    this.isBusy = false,
    this.busyStatus,
    this.backupDirectoryPath = '',
    this.frequency = AutoBackupFrequency.every12Hours,
    this.lastAutoBackupAt,
    this.autoBackups = const [],
    this.storageUsageBytes = 0,
    this.storageFileCount = 0,
    this.userErrorMessage,
    this.successMessage,
  });

  BackupUiState copyWith({
    bool? isBusy,
    String? busyStatus,
    bool clearBusyStatus = false,
    String? backupDirectoryPath,
    AutoBackupFrequency? frequency,
    DateTime? lastAutoBackupAt,
    List<BackupFileInfo>? autoBackups,
    int? storageUsageBytes,
    int? storageFileCount,
    String? userErrorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return BackupUiState(
      isBusy: isBusy ?? this.isBusy,
      busyStatus: clearBusyStatus ? null : (busyStatus ?? this.busyStatus),
      backupDirectoryPath: backupDirectoryPath ?? this.backupDirectoryPath,
      frequency: frequency ?? this.frequency,
      lastAutoBackupAt: lastAutoBackupAt ?? this.lastAutoBackupAt,
      autoBackups: autoBackups ?? this.autoBackups,
      storageUsageBytes: storageUsageBytes ?? this.storageUsageBytes,
      storageFileCount: storageFileCount ?? this.storageFileCount,
      userErrorMessage: clearError ? null : (userErrorMessage ?? this.userErrorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class BackupViewModel extends StateNotifier<BackupUiState> {
  final BackupRepository _repository;
  final BackupPreferencesService _prefsService;
  final AutoBackupScheduler _scheduler;
  final CurrencyService _currencyService;
  final BackupFileService _fileService;

  BackupViewModel(
    this._repository,
    this._prefsService,
    this._scheduler,
    this._currencyService, {
    BackupFileService? fileService,
  })  : _fileService = fileService ?? BackupFileService(),
        super(const BackupUiState()) {
    loadState();
  }

  Future<void> loadState() async {
    final path = await _repository.getBackupDirectoryPath();
    final freq = _prefsService.getFrequency();
    final lastRun = _prefsService.getLastAutoBackupAt();
    final backups = await _repository.listAutoBackups();
    final usage = await _repository.getStorageUsage();

    state = state.copyWith(
      backupDirectoryPath: path,
      frequency: freq,
      lastAutoBackupAt: lastRun,
      autoBackups: backups,
      storageFileCount: usage.fileCount,
      storageUsageBytes: usage.totalSizeBytes,
      clearError: true,
      clearSuccess: true,
    );
  }

  Future<void> createManualBackup() async {
    if (state.isBusy) return;

    state = state.copyWith(
      isBusy: true,
      busyStatus: 'Creating backup...',
      clearError: true,
      clearSuccess: true,
    );

    try {
      final bytes = await _repository.createBackupBytes();
      final defaultFileName = _fileService.generateManualFileName();

      final outputFilePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save backup file',
        fileName: defaultFileName,
        type: FileType.any,
        bytes: bytes,
      );

      if (outputFilePath == null) {
        // User cancelled picker -> silent no-op
        state = state.copyWith(isBusy: false, clearBusyStatus: true);
        return;
      }

      final file = File(outputFilePath);
      if (!await file.exists() || await file.length() == 0) {
        await file.writeAsBytes(bytes, flush: true);
      }

      state = state.copyWith(
        isBusy: false,
        clearBusyStatus: true,
        successMessage: 'Backup saved: $defaultFileName',
      );
    } on BackupFailure catch (e) {
      state = state.copyWith(
        isBusy: false,
        clearBusyStatus: true,
        userErrorMessage: _mapFailureToMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        clearBusyStatus: true,
        userErrorMessage: 'Failed to create backup: $e',
      );
    }
  }

  Future<({Uint8List bytes, BackupSummary summary, String fileName})?> pickAndInspectBackupFile() async {
    if (state.isBusy) return null;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        // Cancelled -> silent no-op
        return null;
      }

      final pickedFile = result.files.first;
      Uint8List? bytes = pickedFile.bytes;
      if (bytes == null && pickedFile.path != null) {
        bytes = await File(pickedFile.path!).readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) {
        state = state.copyWith(
          userErrorMessage: 'The chosen file could not be read.',
        );
        return null;
      }

      state = state.copyWith(
        isBusy: true,
        busyStatus: 'Validating backup...',
        clearError: true,
        clearSuccess: true,
      );

      final summary = await _repository.inspectBackup(bytes);

      state = state.copyWith(isBusy: false, clearBusyStatus: true);
      return (bytes: bytes, summary: summary, fileName: pickedFile.name);
    } on BackupFailure catch (e) {
      state = state.copyWith(
        isBusy: false,
        clearBusyStatus: true,
        userErrorMessage: _mapFailureToMessage(e),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        clearBusyStatus: true,
        userErrorMessage: 'Invalid backup file: $e',
      );
      return null;
    }
  }

  Future<({Uint8List bytes, BackupSummary summary, String fileName})?> inspectExistingFile(File file) async {
    if (state.isBusy) return null;

    try {
      state = state.copyWith(
        isBusy: true,
        busyStatus: 'Validating backup...',
        clearError: true,
        clearSuccess: true,
      );

      final bytes = await file.readAsBytes();
      final summary = await _repository.inspectBackup(bytes);
      final fileName = file.uri.pathSegments.last;

      state = state.copyWith(isBusy: false, clearBusyStatus: true);
      return (bytes: bytes, summary: summary, fileName: fileName);
    } on BackupFailure catch (e) {
      state = state.copyWith(
        isBusy: false,
        clearBusyStatus: true,
        userErrorMessage: _mapFailureToMessage(e),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        clearBusyStatus: true,
        userErrorMessage: 'Invalid backup file: $e',
      );
      return null;
    }
  }

  Future<bool> restoreBackup(Uint8List bytes, {required BackupSummary summary}) async {
    if (state.isBusy) return false;

    state = state.copyWith(
      isBusy: true,
      busyStatus: 'Restoring data...',
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _repository.restoreBackup(
        bytes,
        currencyService: _currencyService,
      );

      await loadState();

      state = state.copyWith(
        isBusy: false,
        clearBusyStatus: true,
        successMessage:
            'Restored ${summary.transactionCount} transactions, ${summary.categoryCount} categories, and ${summary.budgetCount} budgets.',
      );
      return true;
    } on BackupFailure catch (e) {
      state = state.copyWith(
        isBusy: false,
        clearBusyStatus: true,
        userErrorMessage: _mapFailureToMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        clearBusyStatus: true,
        userErrorMessage: 'Restore failed: $e',
      );
      return false;
    }
  }

  Future<void> setFrequency(AutoBackupFrequency frequency) async {
    state = state.copyWith(frequency: frequency);
    try {
      await _scheduler.updateSchedule(frequency);
    } catch (_) {}
  }

  Future<void> deleteAutoBackup(File file) async {
    await _repository.deleteBackupFile(file);
    final backups = await _repository.listAutoBackups();
    final usage = await _repository.getStorageUsage();
    state = state.copyWith(
      autoBackups: backups,
      storageFileCount: usage.fileCount,
      storageUsageBytes: usage.totalSizeBytes,
      successMessage: 'Backup deleted',
    );
  }

  Future<void> shareAutoBackup(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Fynza Backup',
      );
    } catch (e) {
      state = state.copyWith(userErrorMessage: 'Failed to share backup: $e');
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  String _mapFailureToMessage(BackupFailure failure) {
    return switch (failure) {
      InvalidFileFailure(:final message) => message,
      UnsupportedVersionFailure(:final message) => message,
      CorruptDataFailure(:final message) => 'Backup data is invalid: $message',
      StorageErrorFailure(:final message) => 'Storage error: $message',
      UnknownBackupFailure(:final message) => message,
    };
  }
}

final backupViewModelProvider =
    StateNotifierProvider<BackupViewModel, BackupUiState>((ref) {
  final repository = ref.watch(backupRepositoryProvider);
  final prefsService = ref.watch(backupPreferencesServiceProvider);
  final scheduler = ref.watch(autoBackupSchedulerProvider);
  final currencyService = ref.watch(currencyServiceProvider);

  return BackupViewModel(
    repository,
    prefsService,
    scheduler,
    currencyService,
  );
});
