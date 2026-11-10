import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/database_provider.dart';
import '../../../../core/constants/capture_constants.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/providers/global_month_provider.dart';
import '../../../../shared/widgets/fading_scroll_boundary.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../auto_capture/presentation/view_models/capture_inbox_view_model.dart';
import '../../../auto_capture/presentation/views/capture_inbox_view.dart';
import '../../../budget/presentation/view_models/budget_notifier.dart';
import '../../../budget/presentation/views/budget_screen.dart';
import '../../../categories/presentation/view_models/categories_notifier.dart';
import '../../../categories/presentation/views/categories_screen.dart';
import '../../../transactions/presentation/views/transaction_form_screen.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../view_models/dashboard_notifier.dart';
import '../widgets/spending_pie_chart.dart';
import '../widgets/summary_cards.dart';
import 'spending_breakdown_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToTransactions;

  const DashboardScreen({super.key, this.onNavigateToTransactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final selectedMonth = ref.watch(globalMonthProvider);
    final monthNotifier = ref.read(globalMonthProvider.notifier);
    final currency = ref.watch(selectedCurrencyProvider);

    // Watch Categories for expense and income counts
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? const [];
    final expenseCatCount = categories.where((c) => !c.isIncome).length;
    final incomeCatCount = categories.where((c) => c.isIncome).length;

    // Watch Budgets for overall budget total limit
    final budgetState = ref.watch(budgetNotifierProvider);
    final totalBudgetLimit = budgetState.totalBudgetedCents;

    final summary = dashboardState.summary;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber.withValues(
                  alpha: isDark ? 0.22 : 0.15,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppTheme.primaryAmber,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Fynza',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isDark
                    ? theme.colorScheme.onSurface
                    : AppTheme.textCharcoal,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final isAutoCaptureEnabled = ref.watch(
                autoCaptureEnabledProvider,
              );
              if (!CaptureConstants.isEnabled || !isAutoCaptureEnabled) {
                return const SizedBox.shrink();
              }
              final countAsync = ref.watch(pendingCaptureCountProvider);
              final count = countAsync.valueOrNull ?? 0;
              return IconButton(
                tooltip: 'Capture Inbox',
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: AppTheme.expenseAccent,
                  child: const Icon(Icons.inbox_outlined),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CaptureInboxView(),
                    ),
                  );
                },
              );
            },
          ),
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
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadingScrollBoundary(
              fadeHeight: 28.0,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Friendly Greeting Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back! 👋',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : AppTheme.textTaupe,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Financial Overview',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Financial Overview Cards (Net Balance + Blush Expense & Mint Income)
                    SummaryCards(
                      totalIncomeCents: summary.totalIncomeCents,
                      totalExpenseCents: summary.totalExpenseCents,
                      netBalanceCents: summary.netBalanceCents,
                    ),
                    const SizedBox(height: 20),

                    SpendingOverviewCard(
                      spendings: summary.categorySpendings,
                      totalExpenseCents: summary.totalExpenseCents,
                      onDetails: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SpendingBreakdownScreen(
                              spendings: summary.categorySpendings,
                              totalExpenseCents: summary.totalExpenseCents,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Quick Access Navigation (Square Budgets & Categories Cards)
                    Row(
                      children: [
                        // Budgets Card (Square Widget Style)
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: PressableScale(
                              targetScale: 0.96,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BudgetScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.colorScheme.surfaceContainerLow
                                      : AppTheme.cardWhite,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isDark
                                        ? theme.colorScheme.outlineVariant
                                              .withValues(alpha: 0.25)
                                        : AppTheme.borderCream,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.2)
                                          : AppTheme.primaryAmber.withValues(
                                              alpha: 0.05,
                                            ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Top: Icon badge
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF2E233C)
                                            : const Color(0xFFF3ECFA),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.pie_chart_rounded,
                                        color: Color(0xFF8E61C9),
                                        size: 22,
                                      ),
                                    ),
                                    // Bottom: Overall Budget pill above Budgets name
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Overall Budget Pill Indicator
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF2E233C)
                                                : const Color(0xFFF3ECFA),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF4A385E)
                                                  : const Color(0xFFE2D4F5),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons
                                                    .account_balance_wallet_rounded,
                                                size: 11,
                                                color: Color(0xFF8E61C9),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                CurrencyFormatter.formatCents(
                                                  totalBudgetLimit,
                                                  currency,
                                                ),
                                                style: const TextStyle(
                                                  color: Color(0xFF8E61C9),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Budgets',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.3,
                                                fontSize: 16,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Monthly limits',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? theme
                                                          .colorScheme
                                                          .onSurfaceVariant
                                                    : AppTheme.textTaupe,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Categories Card (Square Widget Style)
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: PressableScale(
                              targetScale: 0.96,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CategoriesScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.colorScheme.surfaceContainerLow
                                      : AppTheme.cardWhite,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isDark
                                        ? theme.colorScheme.outlineVariant
                                              .withValues(alpha: 0.25)
                                        : AppTheme.borderCream,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.2)
                                          : AppTheme.primaryAmber.withValues(
                                              alpha: 0.05,
                                            ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Top: Icon badge
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E2D3B)
                                            : const Color(0xFFEAF4FC),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.category_rounded,
                                        color: Color(0xFF2980B9),
                                        size: 22,
                                      ),
                                    ),
                                    // Bottom: Expense & Income count circles above Categories name
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Expense count badge circle
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF331D1C)
                                                    : AppTheme.expenseCardBg,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark
                                                      ? const Color(0xFF482725)
                                                      : const Color(0xFFF9D5CF),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$expenseCatCount',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFFFF8A80,
                                                          )
                                                        : AppTheme
                                                              .expenseAccent,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Income count badge circle
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF162D20)
                                                    : AppTheme.incomeCardBg,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark
                                                      ? const Color(0xFF1E3E2C)
                                                      : const Color(0xFFD2EEDC),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$incomeCatCount',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF81C784,
                                                          )
                                                        : AppTheme.incomeAccent,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Categories',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.3,
                                                fontSize: 16,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Manage tags',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? theme
                                                          .colorScheme
                                                          .onSurfaceVariant
                                                    : AppTheme.textTaupe,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Transactions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (onNavigateToTransactions != null)
                          TextButton(
                            onPressed: onNavigateToTransactions,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryAmber,
                            ),
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Recent Transactions List or Warm Empty State
                    if (summary.recentTransactions.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme.colorScheme.surfaceContainerLow
                              : AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? theme.colorScheme.outlineVariant.withValues(
                                    alpha: 0.25,
                                  )
                                : AppTheme.borderCream,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.2)
                                  : AppTheme.primaryAmber.withValues(
                                      alpha: 0.04,
                                    ),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAmber.withValues(
                                  alpha: isDark ? 0.2 : 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.savings_outlined,
                                color: AppTheme.primaryAmber,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No transactions yet.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? theme.colorScheme.onSurface
                                    : AppTheme.textCharcoal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + below to add your first transaction',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : AppTheme.textTaupe,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: summary.recentTransactions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = summary.recentTransactions[index];
                          return TransactionTile(
                            item: item,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TransactionFormScreen(initial: item),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
