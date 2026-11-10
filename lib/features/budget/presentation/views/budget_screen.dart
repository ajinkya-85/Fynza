import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/providers/global_month_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/fading_scroll_boundary.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../../../../shared/widgets/spring_progress_bar.dart';
import '../../../categories/presentation/view_models/categories_notifier.dart';
import '../view_models/budget_notifier.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_form_dialog.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  void _showAddBudgetDialog(BuildContext context, WidgetRef ref) async {
    final categoriesState = ref.read(categoriesNotifierProvider);
    final categories = categoriesState.valueOrNull ?? [];
    final expenseCategories = categories.where((c) => !c.isIncome).toList();

    if (expenseCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an expense category first.')),
      );
      return;
    }

    final result = await showDialog<BudgetFormResult>(
      context: context,
      builder: (context) =>
          BudgetFormDialog(availableCategories: expenseCategories),
    );

    if (result != null) {
      await ref
          .read(budgetNotifierProvider.notifier)
          .setBudget(
            categoryId: result.categoryId,
            amountLimitCents: result.amountLimitCents,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final budgetState = ref.watch(budgetNotifierProvider);
    final budgetNotifier = ref.read(budgetNotifierProvider.notifier);
    final currency = ref.watch(selectedCurrencyProvider);
    final selectedMonth = ref.watch(globalMonthProvider);
    final monthNotifier = ref.read(globalMonthProvider.notifier);

    final isOverOverall =
        budgetState.totalSpentCents > budgetState.totalBudgetedCents;
    final overallProgress = budgetState.overallProgress;
    final overallPercent = (overallProgress * 100).toInt();

    return Scaffold(
      appBar: AppBar(
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: MonthSelector(
            selectedDate: selectedMonth,
            onPrevious: monthNotifier.previousMonth,
            onNext: monthNotifier.nextMonth,
          ),
        ),
      ),
      body: budgetState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadingScrollBoundary(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Total Budget Hero Card
                    if (budgetState.overviews.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    theme.colorScheme.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                  ]
                                : [
                                    theme.colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.4),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: isDark ? 0.15 : 0.08,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Budget Overview',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isOverOverall
                                                ? theme.colorScheme.error
                                                : theme.colorScheme.primary)
                                            .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isOverOverall
                                        ? 'Over Budget'
                                        : '$overallPercent%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isOverOverall
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Spent',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.formatCents(
                                        budgetState.totalSpentCents,
                                        currency,
                                      ),
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme.onSurface,
                                            letterSpacing: -0.5,
                                          ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Limit',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.formatCents(
                                        budgetState.totalBudgetedCents,
                                        currency,
                                      ),
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme.onSurface,
                                            letterSpacing: -0.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SpringProgressBar(
                              value: overallProgress,
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Title with count badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Category Budgets',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${budgetState.overviews.length} active',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: budgetState.overviews.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = budgetState.overviews[index];
                          return BudgetCard(
                            overview: item,
                            onEdit: () async {
                              final result = await showDialog<BudgetFormResult>(
                                context: context,
                                builder: (context) => BudgetFormDialog(
                                  availableCategories: [item.category],
                                  initialCategoryId: item.category.id,
                                  initialLimitCents: item.budget.amountLimit,
                                ),
                              );
                              if (result != null) {
                                await budgetNotifier.setBudget(
                                  categoryId: result.categoryId,
                                  amountLimitCents: result.amountLimitCents,
                                );
                              }
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Budget?'),
                                  content: Text(
                                    'Remove budget limit for "${item.category.name}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.error,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await budgetNotifier.deleteBudget(
                                  item.budget.id,
                                );
                              }
                            },
                          );
                        },
                      ),
                    ] else ...[
                      EmptyState(
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'No Budgets Set',
                        subtitle:
                            'Set monthly spending limits for categories to stay on track.',
                        action: FilledButton.tonalIcon(
                          onPressed: () => _showAddBudgetDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Set Budget'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'budget_fab',
        onPressed: () => _showAddBudgetDialog(context, ref),
        tooltip: 'Set Budget',
        child: const Icon(Icons.add),
      ),
    );
  }
}
