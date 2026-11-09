class BackupSummary {
  final int formatVersion;
  final String appVersion;
  final int dbSchemaVersion;
  final DateTime createdAt;
  final int categoryCount;
  final int transactionCount;
  final int budgetCount;

  const BackupSummary({
    required this.formatVersion,
    required this.appVersion,
    required this.dbSchemaVersion,
    required this.createdAt,
    required this.categoryCount,
    required this.transactionCount,
    required this.budgetCount,
  });
}
