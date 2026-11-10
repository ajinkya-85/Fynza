import '../models/auto_backup_frequency.dart';

abstract interface class BackupPreferences {
  AutoBackupFrequency getFrequency();
  DateTime? getLastAutoBackupAt();
  Future<void> setLastAutoBackupAt(DateTime time);
}

abstract interface class BackupScheduleController {
  Future<void> updateSchedule(AutoBackupFrequency frequency);
}

abstract interface class BackupFileNameGenerator {
  String generateManualFileName([DateTime? time]);
}
