enum AutoBackupFrequency {
  off(0, 'Off'),
  every6Hours(6, 'Every 6 hours'),
  every12Hours(12, 'Every 12 hours'),
  daily(24, 'Daily'),
  every2Days(48, 'Every 2 days'),
  weekly(168, 'Weekly');

  final int hours;
  final String label;

  const AutoBackupFrequency(this.hours, this.label);

  static AutoBackupFrequency fromHours(int? hours) {
    if (hours == null) return AutoBackupFrequency.every12Hours;
    return AutoBackupFrequency.values.firstWhere(
      (e) => e.hours == hours,
      orElse: () => AutoBackupFrequency.every12Hours,
    );
  }
}
