import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/backup/data/services/auto_backup_scheduler.dart';
import 'package:expense_tracker/features/backup/domain/models/auto_backup_frequency.dart';

void main() {
  group('shouldRunAutoBackup Tests', () {
    final now = DateTime(2026, 10, 10, 12, 0, 0);

    test('returns false when frequency is off', () {
      expect(shouldRunAutoBackup(now, null, AutoBackupFrequency.off), isFalse);
      expect(
        shouldRunAutoBackup(
          now,
          now.subtract(const Duration(days: 10)),
          AutoBackupFrequency.off,
        ),
        isFalse,
      );
    });

    test('returns true when last backup is null and frequency is enabled', () {
      expect(shouldRunAutoBackup(now, null, AutoBackupFrequency.every12Hours), isTrue);
    });

    test('returns false when interval has not passed yet', () {
      final lastRun = now.subtract(const Duration(hours: 6));
      expect(
        shouldRunAutoBackup(now, lastRun, AutoBackupFrequency.every12Hours),
        isFalse,
      );
    });

    test('returns true when interval has exactly or more passed', () {
      final lastRun12 = now.subtract(const Duration(hours: 12));
      expect(
        shouldRunAutoBackup(now, lastRun12, AutoBackupFrequency.every12Hours),
        isTrue,
      );

      final lastRun24 = now.subtract(const Duration(hours: 24));
      expect(
        shouldRunAutoBackup(now, lastRun24, AutoBackupFrequency.daily),
        isTrue,
      );
    });

    test('returns true if clock was moved backwards', () {
      final futureTime = now.add(const Duration(hours: 5));
      expect(
        shouldRunAutoBackup(now, futureTime, AutoBackupFrequency.every12Hours),
        isTrue,
      );
    });
  });
}
