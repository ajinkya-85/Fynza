class BackupFileInfo {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;

  const BackupFileInfo({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
  });
}
