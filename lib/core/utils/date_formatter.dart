import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullDate = DateFormat('MMMM d, yyyy');
  static final DateFormat _shortDate = DateFormat('MMM d, yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _shortMonthYear = DateFormat('MMM yyyy');
  static final DateFormat _monthDay = DateFormat('MMM d');

  static String fullDate(DateTime date) => _fullDate.format(date);
  static String shortDate(DateTime date) => _shortDate.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);
  static String shortMonthYear(DateTime date) => _shortMonthYear.format(date);
  static String monthDay(DateTime date) => _monthDay.format(date);

  static String groupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = today.difference(target).inDays;
    if (diff == 0) {
      return 'Today, ${DateFormat('MMM d').format(date)}';
    } else if (diff == 1) {
      return 'Yesterday, ${DateFormat('MMM d').format(date)}';
    } else if (date.year == now.year) {
      return DateFormat('EEEE, MMM d').format(date);
    } else {
      return DateFormat('EEE, MMM d, yyyy').format(date);
    }
  }

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final difference = today.difference(target).inDays;
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference == -1) {
      return 'Tomorrow';
    } else if (difference > 1 && difference < 7) {
      return DateFormat('EEEE').format(date); // Day of week
    } else {
      return _shortDate.format(date);
    }
  }
}
