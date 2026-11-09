import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/database_provider.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/models/transaction_with_category.dart';
import '../../../../shared/providers/global_month_provider.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionListState {
  final List<TransactionWithCategory> transactions;
  final bool isLoading;
  final DateTime selectedMonth;
  final TransactionType? typeFilter;
  final int? categoryIdFilter;
  final String searchQuery;

  const TransactionListState({
    required this.transactions,
    required this.isLoading,
    required this.selectedMonth,
    this.typeFilter,
    this.categoryIdFilter,
    this.searchQuery = '',
  });

  factory TransactionListState.initial({DateTime? initialMonth}) {
    final now = initialMonth ?? DateTime.now();
    return TransactionListState(
      transactions: const [],
      isLoading: true,
      selectedMonth: DateTime(now.year, now.month),
    );
  }

  TransactionListState copyWith({
    List<TransactionWithCategory>? transactions,
    bool? isLoading,
    DateTime? selectedMonth,
    TransactionType? typeFilter,
    bool clearTypeFilter = false,
    int? categoryIdFilter,
    bool clearCategoryFilter = false,
    String? searchQuery,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      categoryIdFilter: clearCategoryFilter ? null : (categoryIdFilter ?? this.categoryIdFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<TransactionWithCategory> get filteredTransactions {
    return transactions.where((item) {
      if (typeFilter != null && item.transaction.type != typeFilter) {
        return false;
      }
      if (categoryIdFilter != null && item.transaction.categoryId != categoryIdFilter) {
        return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final noteMatch = item.transaction.note?.toLowerCase().contains(query) ?? false;
        final catMatch = item.category.name.toLowerCase().contains(query);
        if (!noteMatch && !catMatch) return false;
      }
      return true;
    }).toList();
  }
}

class TransactionsNotifier extends StateNotifier<TransactionListState> {
  final TransactionRepository _repository;
  StreamSubscription<List<TransactionWithCategory>>? _subscription;

  TransactionsNotifier(this._repository, {DateTime? initialMonth})
      : super(TransactionListState.initial(initialMonth: initialMonth)) {
    _subscribeToTransactions();
  }

  void _subscribeToTransactions() {
    _subscription?.cancel();
    state = state.copyWith(isLoading: true);

    final start = DateTime(state.selectedMonth.year, state.selectedMonth.month, 1);
    final end = DateTime(state.selectedMonth.year, state.selectedMonth.month + 1, 0, 23, 59, 59, 999);

    _subscription = _repository.watchTransactions(startDate: start, endDate: end).listen(
      (data) {
        state = state.copyWith(transactions: data, isLoading: false);
      },
      onError: (_, _) {
        state = state.copyWith(isLoading: false);
      },
    );
  }

  void setMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    if (state.selectedMonth == normalized) return;
    state = state.copyWith(selectedMonth: normalized);
    _subscribeToTransactions();
  }

  void setTypeFilter(TransactionType? type) {
    if (type == null) {
      state = state.copyWith(clearTypeFilter: true);
    } else {
      state = state.copyWith(typeFilter: type);
    }
  }

  void setCategoryFilter(int? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(categoryIdFilter: categoryId);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.deleteTransaction(id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final transactionsNotifierProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionListState>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final initialMonth = ref.read(globalMonthProvider);
  final notifier = TransactionsNotifier(repository, initialMonth: initialMonth);
  ref.listen<DateTime>(globalMonthProvider, (_, next) {
    notifier.setMonth(next);
  });
  return notifier;
});
