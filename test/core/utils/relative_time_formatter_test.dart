import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/relative_time_formatter.dart';

void main() {
  group('RelativeTimeFormatter Tests', () {
    final now = DateTime(2026, 10, 10, 12, 0, 0);

    test('formats null as Never', () {
      expect(RelativeTimeFormatter.format(null), 'Never');
    });

    test('formats < 60 seconds as Just now', () {
      final t = now.subtract(const Duration(seconds: 30));
      expect(RelativeTimeFormatter.format(t, now: now), 'Just now');
    });

    test('formats minutes correctly', () {
      final t1 = now.subtract(const Duration(minutes: 1));
      expect(RelativeTimeFormatter.format(t1, now: now), '1 minute ago');

      final t5 = now.subtract(const Duration(minutes: 5));
      expect(RelativeTimeFormatter.format(t5, now: now), '5 minutes ago');
    });

    test('formats hours correctly', () {
      final t1 = now.subtract(const Duration(hours: 1));
      expect(RelativeTimeFormatter.format(t1, now: now), '1 hour ago');

      final t4 = now.subtract(const Duration(hours: 4));
      expect(RelativeTimeFormatter.format(t4, now: now), '4 hours ago');
    });

    test('formats 1 day ago as Yesterday', () {
      final t = now.subtract(const Duration(days: 1));
      expect(RelativeTimeFormatter.format(t, now: now), 'Yesterday');
    });

    test('formats multiple days ago', () {
      final t = now.subtract(const Duration(days: 3));
      expect(RelativeTimeFormatter.format(t, now: now), '3 days ago');
    });
  });
}
