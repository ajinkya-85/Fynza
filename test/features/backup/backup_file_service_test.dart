import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynza/features/backup/data/services/backup_file_service.dart';

void main() {
  group('BackupFileService Tests', () {
    late Directory tempDir;
    late BackupFileService fileService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('backup_test_');
      fileService = BackupFileService(customBaseDir: tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Writes atomically and leaves no .tmp files on success', () async {
      final file = File('${tempDir.path}/test.expbak');
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final written = await fileService.writeAtomically(file, bytes);
      expect(await written.exists(), isTrue);
      expect(await written.readAsBytes(), bytes);

      final tmpFile = File('${file.path}.tmp');
      expect(await tmpFile.exists(), isFalse);
    });

    test('Cleans stale .tmp files', () async {
      final staleTmp = File('${tempDir.path}/stale.expbak.tmp');
      await staleTmp.writeAsString('temp');

      await fileService.cleanStaleTempFiles();
      expect(await staleTmp.exists(), isFalse);
    });

    test('Rotates auto backups, keeping only maxBackups newest, without touching other files', () async {
      // Create 5 auto backups with artificial timestamps
      for (var i = 1; i <= 5; i++) {
        final f = File('${tempDir.path}/auto_fynza_2026-10-0${i}_12-00.expbak');
        await f.writeAsString('backup $i');
        // sleep slightly to have distinct modified timestamps
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // Create an unrelated user file
      final userFile = File('${tempDir.path}/notes.txt');
      await userFile.writeAsString('do not delete');

      // Rotate to max 3
      await fileService.rotateAutoBackups(maxBackups: 3);

      final remaining = await fileService.listAutoBackups();
      expect(remaining.length, 3);

      // Unrelated file must still exist
      expect(await userFile.exists(), isTrue);
    });
  });
}
