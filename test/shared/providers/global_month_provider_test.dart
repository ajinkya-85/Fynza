import 'package:expense_tracker/shared/providers/global_month_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlobalMonthNotifier', () {
    test('moves across year boundaries', () {
      final notifier = GlobalMonthNotifier();
      notifier.setMonth(DateTime(2026, 12, 31));

      notifier.nextMonth();
      expect(notifier.state, DateTime(2027, 1));

      notifier.previousMonth();
      expect(notifier.state, DateTime(2026, 12));

      notifier.dispose();
    });

    test('normalizes a selected date to the first day of its month', () {
      final notifier = GlobalMonthNotifier();
      notifier.setMonth(DateTime(2026, 5, 18));

      expect(notifier.state, DateTime(2026, 5));

      notifier.dispose();
    });
  });
}
