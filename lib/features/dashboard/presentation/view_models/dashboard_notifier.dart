import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/database_provider.dart';
import '../../../../shared/providers/global_month_provider.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardState {
  final DashboardSummary summary;
  final int selectedMonth;
  final int selectedYear;
  final bool isLoading;

  const DashboardState({
    required this.summary,
    required this.selectedMonth,
    required this.selectedYear,
    required this.isLoading,
  });

  factory DashboardState.initial({DateTime? initialMonth}) {
    final now = initialMonth ?? DateTime.now();
    return DashboardState(
      summary: const DashboardSummary.empty(),
      selectedMonth: now.month,
      selectedYear: now.year,
      isLoading: true,
    );
  }

  DashboardState copyWith({
    DashboardSummary? summary,
    int? selectedMonth,
    int? selectedYear,
    bool? isLoading,
  }) {
    return DashboardState(
      summary: summary ?? this.summary,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;
  StreamSubscription<DashboardSummary>? _subscription;

  DashboardNotifier(this._repository, {DateTime? initialMonth})
      : super(DashboardState.initial(initialMonth: initialMonth)) {
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    state = state.copyWith(isLoading: true);

    _subscription = _repository
        .watchDashboardSummary(
          month: state.selectedMonth,
          year: state.selectedYear,
        )
        .listen(
          (summary) {
            state = state.copyWith(summary: summary, isLoading: false);
          },
          onError: (_, _) {
            state = state.copyWith(isLoading: false);
          },
        );
  }

  void setMonth(int month, int year) {
    if (state.selectedMonth == month && state.selectedYear == year) return;
    state = state.copyWith(selectedMonth: month, selectedYear: year);
    _subscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  final initialMonth = ref.read(globalMonthProvider);
  final notifier = DashboardNotifier(repository, initialMonth: initialMonth);
  ref.listen<DateTime>(globalMonthProvider, (_, next) {
    notifier.setMonth(next.month, next.year);
  });
  return notifier;
});
