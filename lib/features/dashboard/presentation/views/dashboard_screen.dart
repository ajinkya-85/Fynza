import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/capture_constants.dart';
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
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final selectedMonth = ref.watch(globalMonthProvider);
    final monthNotifier = ref.read(globalMonthProvider.notifier);

    final summary = dashboardState.summary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Fynza',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Financial Overview Cards
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (onNavigateToTransactions != null)
                        TextButton(
                          onPressed: onNavigateToTransactions,
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Recent Transactions List
                  if (summary.recentTransactions.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.brightness == Brightness.dark
                              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
                              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No transactions yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: summary.recentTransactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
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
