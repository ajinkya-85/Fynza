import 'package:intl/intl.dart';

class RelativeTimeFormatter {
  static String format(DateTime? time, {DateTime? now}) {
    if (time == null) return 'Never';

    final current = now ?? DateTime.now();
    final difference = current.difference(time);

    if (difference.isNegative) {
      return DateFormat.yMMMd().format(time);
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins == 1 ? '1 minute ago' : '$mins minutes ago';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return DateFormat.yMMMd().format(time);
  }
}
