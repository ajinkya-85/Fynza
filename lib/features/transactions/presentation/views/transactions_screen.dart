import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/models/transaction_with_category.dart';
import '../../../../shared/providers/global_month_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/fading_scroll_boundary.dart';
import '../../../../shared/widgets/fluid_segmented_control.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../view_models/transactions_notifier.dart';
import '../widgets/transaction_date_header.dart';
import '../widgets/transaction_search_bar.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_form_screen.dart';

/// Helper model representing transactions grouped by calendar day.
class _DateGroup {
  final DateTime date;
  final List<TransactionWithCategory> items;
  final int netAmountCents;

  const _DateGroup({
    required this.date,
    required this.items,
    required this.netAmountCents,
  });
}

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final currentQuery = ref.read(transactionsNotifierProvider).searchQuery;
    _searchController = TextEditingController(text: currentQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_DateGroup> _groupByDate(List<TransactionWithCategory> items) {
    if (items.isEmpty) return const [];

    final Map<DateTime, List<TransactionWithCategory>> map = {};
    for (final item in items) {
      final d = item.transaction.date;
      final dayKey = DateTime(d.year, d.month, d.day);
      map.putIfAbsent(dayKey, () => []).add(item);
    }

    final groups = <_DateGroup>[];
    for (final entry in map.entries) {
      int net = 0;
      for (final item in entry.value) {
        if (item.transaction.type == TransactionType.income) {
          net += item.transaction.amount;
        } else {
          net -= item.transaction.amount;
        }
      }
      groups.add(
        _DateGroup(
          date: entry.key,
          items: entry.value,
          netAmountCents: net,
        ),
      );
    }

    // Ensure sorted descending by date
    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(transactionsNotifierProvider);
    final notifier = ref.read(transactionsNotifierProvider.notifier);
    final selectedMonth = ref.watch(globalMonthProvider);
    final monthNotifier = ref.read(globalMonthProvider.notifier);

    final filtered = state.filteredTransactions;
    final groups = _groupByDate(filtered);

    // Sync search controller if state is reset externally
    if (_searchController.text != state.searchQuery) {
      _searchController.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Fynza',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add Transaction',
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TransactionFormScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: MonthSelector(
            selectedDate: selectedMonth,
            onPrevious: monthNotifier.previousMonth,
            onNext: monthNotifier.nextMonth,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Apple-style Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TransactionSearchBar(
              controller: _searchController,
              onChanged: notifier.setSearchQuery,
              onClear: () => notifier.setSearchQuery(''),
            ),
          ),
          const SizedBox(height: 8),

          // Fluid Segmented Control Filter (All / Expenses / Income)
          FluidSegmentedControl<TransactionType?>(
            items: const [null, TransactionType.expense, TransactionType.income],
            selectedItem: state.typeFilter,
            onSelectedItemChanged: (type) => notifier.setTypeFilter(type),
            labelBuilder: (type) =>
                type == null ? 'All' : (type.isExpense ? 'Expenses' : 'Income'),
            iconBuilder: (type) => type == null
                ? null
                : (type.isExpense
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded),
          ),
          const SizedBox(height: 4),

          // Main Content
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? (state.searchQuery.isNotEmpty || state.typeFilter != null
                        ? EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No Matching Transactions',
                            subtitle:
                                'Try adjusting your search query or type filter.',
                            action: FilledButton.tonalIcon(
                              onPressed: () {
                                notifier.setSearchQuery('');
                                notifier.setTypeFilter(null);
                              },
                              icon: const Icon(Icons.clear_rounded),
                              label: const Text('Reset Filters'),
                            ),
                          )
                        : EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No Transactions',
                            subtitle:
                                'No records found for ${DateFormatter.monthYear(selectedMonth)}',
                            action: FilledButton.tonalIcon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TransactionFormScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Transaction'),
                            ),
                          ))
                    : FadingScrollBoundary(
                        fadeHeight: 28.0,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        itemCount: groups.length,
                        itemBuilder: (context, groupIndex) {
                          final group = groups[groupIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TransactionDateHeader(
                                date: group.date,
                                netAmountCents: group.netAmountCents,
                              ),
                              const SizedBox(height: 4),
                              ...group.items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Dismissible(
                                    key: ValueKey(item.transaction.id),
                                    direction: DismissDirection.endToStart,
                                    onUpdate: (details) {
                                      if (details.reached &&
                                          !details.previousReached) {
                                        HapticFeedback.mediumImpact();
                                      }
                                    },
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Delete',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                              'Delete Transaction?'),
                                          content: const Text(
                                            'Are you sure you want to delete this transaction?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    theme.colorScheme.error,
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onDismissed: (_) {
                                      notifier.deleteTransaction(
                                          item.transaction.id);
                                    },
                                    child: TransactionTile(
                                      item: item,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TransactionFormScreen(
                                                    initial: item),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 6),
                            ],
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
