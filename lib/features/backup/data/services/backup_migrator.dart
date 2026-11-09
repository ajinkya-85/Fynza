import '../services/backup_serializer.dart';

class BackupMigrator {
  /// Migrates raw JSON map from its recorded formatVersion up to [BackupSerializer.currentFormatVersion].
  Map<String, dynamic> migrate(Map<String, dynamic> rawJson) {
    var version = rawJson['formatVersion'] as int? ?? 1;

    var current = Map<String, dynamic>.from(rawJson);

    while (version < BackupSerializer.currentFormatVersion) {
      current = _stepMigration(current, version);
      version = current['formatVersion'] as int;
    }

    return current;
  }

  Map<String, dynamic> _stepMigration(Map<String, dynamic> data, int fromVersion) {
    // V1 is the initial version, so this is currently a no-op hook.
    switch (fromVersion) {
      default:
        return data;
    }
  }
}
