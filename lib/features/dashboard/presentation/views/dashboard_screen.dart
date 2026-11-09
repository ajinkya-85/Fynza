import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/capture_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/global_month_provider.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../../../auto_capture/data/services/capture_preferences_service.dart';
import '../../../auto_capture/presentation/view_models/capture_inbox_view_model.dart';
import '../../../auto_capture/presentation/views/capture_inbox_view.dart';
import '../../../transactions/presentation/views/transaction_form_screen.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../view_models/dashboard_notifier.dart';
import '../widgets/spending_pie_chart.dart';
import '../widgets/summary_cards.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToTransactions;

  const DashboardScreen({
    super.key,
    this.onNavigateToTransactions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final selectedMonth = ref.watch(globalMonthProvider);
    final monthNotifier = ref.read(globalMonthProvider.notifier);

    final summary = dashboardState.summary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primaryAmber.withValues(alpha: isDark ? 0.22 : 0.15),
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
                color: isDark ? theme.colorScheme.onSurface : AppTheme.textCharcoal,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final isAutoCaptureEnabled = ref.watch(autoCaptureEnabledProvider);
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
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                  // Spending Breakdown Pie Chart (fl_chart)
                  SpendingPieChart(
                    spendings: summary.categorySpendings,
                    totalExpenseCents: summary.totalExpenseCents,
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
                              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.25)
                              : AppTheme.borderCream,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : AppTheme.primaryAmber.withValues(alpha: 0.04),
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
                              color: AppTheme.primaryAmber
                                  .withValues(alpha: isDark ? 0.2 : 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
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
    );
  }
}
