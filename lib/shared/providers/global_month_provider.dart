import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalMonthNotifier extends StateNotifier<DateTime> {
  GlobalMonthNotifier() : super(_initialMonth());

  static DateTime _initialMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }

  void resetToCurrentMonth() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month);
  }
}

final globalMonthProvider =
    StateNotifierProvider<GlobalMonthNotifier, DateTime>((ref) {
  return GlobalMonthNotifier();
});
