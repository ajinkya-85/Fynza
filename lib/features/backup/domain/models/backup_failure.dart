sealed class BackupFailure implements Exception {
  final String message;
  const BackupFailure(this.message);

  @override
  String toString() => message;
}

class InvalidFileFailure extends BackupFailure {
  const InvalidFileFailure([super.message = 'The selected file is not a valid backup file.']);
}

class UnsupportedVersionFailure extends BackupFailure {
  final int version;
  const UnsupportedVersionFailure(this.version)
      : super('This backup was created with a newer version of the app (v$version) and cannot be restored.');
}

class CorruptDataFailure extends BackupFailure {
  const CorruptDataFailure(super.message);
}

class StorageErrorFailure extends BackupFailure {
  const StorageErrorFailure(super.message);
}

class UnknownBackupFailure extends BackupFailure {
  const UnknownBackupFailure([super.message = 'An unexpected error occurred during backup or restore.']);
}
