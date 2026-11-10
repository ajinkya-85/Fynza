import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/backup_failure.dart';
import '../../domain/models/backup_file_info.dart';
import '../../domain/services/backup_services.dart';
import 'backup_serializer.dart';

class BackupFileService implements BackupFileNameGenerator {
  static const String appSlug = 'Fynza';
  static const int defaultMaxAutoBackups = 3;
  static const int defaultMaxPreRestoreBackups = 2;

  final DateFormat _fileDateFormatter = DateFormat('yyyy-MM-dd_HH-mm');
  final DateFormat _safetyDateFormatter = DateFormat('yyyy-MM-dd_HH-mm-ss');

  final Directory? customBaseDir;

  BackupFileService({this.customBaseDir});

  /// Resolves the primary backups directory.
  Future<Directory> getBackupDirectory() async {
    final custom = customBaseDir;
    if (custom != null) {
      if (!await custom.exists()) {
        await custom.create(recursive: true);
      }
      return custom;
    }

    Directory? base;
    try {
      if (Platform.isAndroid) {
        base = await getExternalStorageDirectory();
      }
    } catch (_) {
      base = null;
    }

    base ??= await getApplicationDocumentsDirectory();
    final backupDir = Directory('${base.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Resolves the pre-restore safety backups directory.
  Future<Directory> getPreRestoreDirectory() async {
    final backupDir = await getBackupDirectory();
    final preRestoreDir = Directory('${backupDir.path}/pre_restore');
    if (!await preRestoreDir.exists()) {
      await preRestoreDir.create(recursive: true);
    }
    return preRestoreDir;
  }

  /// Generates manual backup file name.
  @override
  String generateManualFileName([DateTime? time]) {
    final now = time ?? DateTime.now();
    final formatted = _fileDateFormatter.format(now);
    return '${appSlug}_$formatted.${BackupSerializer.backupExtension}';
  }

  /// Generates automatic backup file name.
  String generateAutoFileName([DateTime? time]) {
    final now = time ?? DateTime.now();
    final formatted = _fileDateFormatter.format(now);
    return 'auto_${appSlug}_$formatted.${BackupSerializer.backupExtension}';
  }

  /// Generates pre-restore safety backup file name.
  String generatePreRestoreFileName([DateTime? time]) {
    final now = time ?? DateTime.now();
    final formatted = _safetyDateFormatter.format(now);
    return 'pre_restore_${appSlug}_$formatted.${BackupSerializer.backupExtension}';
  }

  /// Writes [bytes] atomically to [targetFile] by first writing to a `.tmp` file.
  Future<File> writeAtomically(File targetFile, Uint8List bytes) async {
    final tempFile = File('${targetFile.path}.tmp');
    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      await tempFile.writeAsBytes(bytes, flush: true);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      return await tempFile.rename(targetFile.path);
    } catch (e) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      throw StorageErrorFailure('Failed to write backup file: $e');
    }
  }

  /// Cleans any stale `.tmp` files in the backup directory and pre-restore directory.
  Future<void> cleanStaleTempFiles() async {
    try {
      final dir = await getBackupDirectory();
      await _cleanTempFilesInDir(dir);
      final preDir = await getPreRestoreDirectory();
      await _cleanTempFilesInDir(preDir);
    } catch (_) {}
  }

  Future<void> _cleanTempFilesInDir(Directory dir) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.tmp')) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  /// Saves an auto backup and rotates old ones.
  Future<File> saveAutoBackup(
    Uint8List bytes, {
    int maxBackups = defaultMaxAutoBackups,
  }) async {
    await cleanStaleTempFiles();
    final dir = await getBackupDirectory();
    final fileName = generateAutoFileName();
    final file = File('${dir.path}/$fileName');

    final writtenFile = await writeAtomically(file, bytes);
    await rotateAutoBackups(maxBackups: maxBackups);
    return writtenFile;
  }

  /// Saves a pre-restore safety backup and rotates old ones.
  Future<File> savePreRestoreBackup(
    Uint8List bytes, {
    int maxBackups = defaultMaxPreRestoreBackups,
  }) async {
    await cleanStaleTempFiles();
    final dir = await getPreRestoreDirectory();
    final fileName = generatePreRestoreFileName();
    final file = File('${dir.path}/$fileName');

    final writtenFile = await writeAtomically(file, bytes);
    await rotatePreRestoreBackups(maxBackups: maxBackups);
    return writtenFile;
  }

  /// Lists all automatic backup files sorted newest first.
  Future<List<BackupFileInfo>> listAutoBackups() async {
    final dir = await getBackupDirectory();
    if (!await dir.exists()) return [];

    final list = <BackupFileInfo>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        final name = entity.uri.pathSegments.last;
        if ((name.startsWith('auto_fynza_') ||
                name.startsWith('auto_expense_tracker_')) &&
            name.endsWith('.${BackupSerializer.backupExtension}')) {
          final stat = await entity.stat();
          list.add(
            BackupFileInfo(
              path: entity.path,
              name: name,
              sizeBytes: stat.size,
              modifiedAt: stat.modified,
            ),
          );
        }
      }
    }

    list.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return list;
  }

  /// Rotates auto backup files, keeping only the newest [maxBackups].
  Future<void> rotateAutoBackups({
    int maxBackups = defaultMaxAutoBackups,
  }) async {
    final files = await listAutoBackups();
    if (files.length <= maxBackups) return;

    for (var i = maxBackups; i < files.length; i++) {
      try {
        final file = File(files[i].path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  /// Rotates pre-restore safety backups, keeping only the newest [maxBackups].
  Future<void> rotatePreRestoreBackups({
    int maxBackups = defaultMaxPreRestoreBackups,
  }) async {
    final dir = await getPreRestoreDirectory();
    if (!await dir.exists()) return;

    final list = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        final name = entity.uri.pathSegments.last;
        if ((name.startsWith('pre_restore_fynza_') ||
                name.startsWith('pre_restore_expense_tracker_')) &&
            name.endsWith('.${BackupSerializer.backupExtension}')) {
          list.add(entity);
        }
      }
    }

    final statList = <MapEntry<File, DateTime>>[];
    for (final file in list) {
      final stat = await file.stat();
      statList.add(MapEntry(file, stat.modified));
    }
    statList.sort((a, b) => b.value.compareTo(a.value));

    if (statList.length <= maxBackups) return;

    for (var i = maxBackups; i < statList.length; i++) {
      try {
        if (await statList[i].key.exists()) {
          await statList[i].key.delete();
        }
      } catch (_) {}
    }
  }

  /// Deletes a specific backup file.
  Future<void> deleteBackupFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Calculates total size and file count of automatic backups.
  Future<({int fileCount, int totalSizeBytes})> getStorageUsage() async {
    final files = await listAutoBackups();
    final totalSize = files.fold<int>(0, (sum, f) => sum + f.sizeBytes);
    return (fileCount: files.length, totalSizeBytes: totalSize);
  }
}
