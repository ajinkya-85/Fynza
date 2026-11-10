import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/auto_backup_frequency.dart';
import '../../domain/services/backup_services.dart';

class BackupPreferencesService implements BackupPreferences {
  static const String _keyFrequencyHours = 'auto_backup_frequency_hours';
  static const String _keyLastBackupAt = 'auto_backup_last_at_ms';
  static const String _keyMaxAutoBackups = 'auto_backup_max_files';

  final SharedPreferences _prefs;

  BackupPreferencesService(this._prefs);

  @override
  AutoBackupFrequency getFrequency() {
    final hours = _prefs.getInt(_keyFrequencyHours);
    return AutoBackupFrequency.fromHours(hours);
  }

  Future<void> setFrequency(AutoBackupFrequency frequency) async {
    await _prefs.setInt(_keyFrequencyHours, frequency.hours);
  }

  @override
  DateTime? getLastAutoBackupAt() {
    final ms = _prefs.getInt(_keyLastBackupAt);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }

  @override
  Future<void> setLastAutoBackupAt(DateTime time) async {
    await _prefs.setInt(_keyLastBackupAt, time.toUtc().millisecondsSinceEpoch);
  }

  int getMaxAutoBackups() {
    return _prefs.getInt(_keyMaxAutoBackups) ?? 3;
  }
}
