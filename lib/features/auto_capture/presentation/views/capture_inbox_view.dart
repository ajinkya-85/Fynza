import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/app_currency.dart';
import '../../../../shared/providers/app_alert_provider.dart';
import '../../../../shared/widgets/fading_scroll_boundary.dart';
import '../../../transactions/presentation/views/transaction_form_screen.dart';
import '../../domain/models/capture_item.dart';
import '../view_models/capture_inbox_view_model.dart';

class CaptureInboxView extends ConsumerWidget {
  const CaptureInboxView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(captureInboxViewModelProvider);
    final viewModel = ref.read(captureInboxViewModelProvider.notifier);
    final currency = ref.watch(selectedCurrencyProvider);
    final repeatedItems = state.pendingItems
        .where((item) => item.duplicateCount > 0)
        .toList();
    final reviewItems = state.pendingItems
        .where((item) => item.duplicateCount == 0)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Inbox'),
        actions: [
          IconButton(
            tooltip: 'Refresh / Drain Queue',
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.drain(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
          ? Center(child: Text(state.errorMessage!))
          : RefreshIndicator(
              onRefresh: () => viewModel.drain(),
              child: FadingScrollBoundary(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!state.isPermissionGranted) ...[
                      _buildPermissionBanner(context, viewModel),
                      const SizedBox(height: 16),
                    ],
                    if (state.pendingItems.isEmpty &&
                        state.recentlyAutoAdded.isEmpty)
                      _buildEmptyState(context)
                    else ...[
                      if (reviewItems.isNotEmpty) ...[
                        Text(
                          'Pending Review (${reviewItems.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...reviewItems.map(
                          (item) => _buildPendingItemTile(
                            context,
                            ref,
                            item,
                            viewModel,
                            currency,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (repeatedItems.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Repeated Notifications (${repeatedItems.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Same transaction reference received again. Add it once if valid.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...repeatedItems.map(
                          (item) => _buildPendingItemTile(
                            context,
                            ref,
                            item,
                            viewModel,
                            currency,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (state.recentlyAutoAdded.isNotEmpty) ...[
                        Text(
                          'Recently Auto-Added',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...state.recentlyAutoAdded.map(
                          (item) => _buildAutoAddedTile(
                            context,
                            ref,
                            item,
                            viewModel,
                            currency,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPermissionBanner(
    BuildContext context,
    CaptureInboxViewModel vm,
  ) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer.withAlpha(90),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.notification_important, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Access Needed',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  Text(
                    'Enable Notification access so Fynza can capture bank SMS notifications.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => vm.openPermissionSettings(),
              child: const Text('Fix'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingItemTile(
    BuildContext context,
    WidgetRef ref,
    CaptureItem item,
    CaptureInboxViewModel vm,
    AppCurrency currency,
  ) {
    final theme = Theme.of(context);
    final isExpense = item.type.isExpense;
    final isDark = theme.brightness == Brightness.dark;
    final amountColor = isExpense
        ? (isDark ? const Color(0xFFFF8A80) : AppTheme.expenseAccent)
        : (isDark ? const Color(0xFF81C784) : AppTheme.incomeAccent);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.counterparty ?? 'Bank transaction',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.sender} • ${DateFormatter.fullDate(item.occurredAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Text(
                    '${isExpense ? '-' : '+'}${CurrencyFormatter.formatCents(item.amountCents, currency)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ),
              ],
            ),
            if (item.accountLast4 != null || item.reference != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (item.accountLast4 != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '•••• ${item.accountLast4}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  if (item.reference != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Ref: ${item.reference}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (item.duplicateCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Received ${item.duplicateCount + 1} times • Add once',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => TransactionFormScreen(
                          captureIdToConfirm: item.id,
                          prefilledAmountCents: item.amountCents,
                          prefilledType: item.type,
                          prefilledCategoryId: item.suggestedCategoryId,
                          prefilledDate: item.occurredAt,
                          prefilledNote:
                              item.counterparty ?? 'Bank transaction',
                        ),
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    await vm.dismiss(item.id);
                    if (context.mounted) {
                      ref
                          .read(appAlertProvider.notifier)
                          .show(
                            'Transaction dismissed',
                            tone: AppAlertTone.information,
                            actionLabel: 'Undo',
                            onAction: () => vm.undoDismiss(item.id),
                          );
                    }
                  },
                  child: const Text('Dismiss'),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'ignore') {
                      vm.ignoreSender(item.sender);
                      ref
                          .read(appAlertProvider.notifier)
                          .show(
                            'Ignored all messages from ${item.sender}',
                            tone: AppAlertTone.success,
                          );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'ignore',
                      child: Text('Ignore "${item.sender}"'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoAddedTile(
    BuildContext context,
    WidgetRef ref,
    CaptureItem item,
    CaptureInboxViewModel vm,
    AppCurrency currency,
  ) {
    final theme = Theme.of(context);
    final isExpense = item.type.isExpense;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.counterparty ?? 'Bank transaction'),
        subtitle: Text(
          '${item.sender} • ${DateFormatter.fullDate(item.occurredAt)}',
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${isExpense ? '-' : '+'}${CurrencyFormatter.formatCents(item.amountCents, currency)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExpense
                        ? (isDark
                              ? const Color(0xFFFF8A80)
                              : AppTheme.expenseAccent)
                        : (isDark
                              ? const Color(0xFF81C784)
                              : AppTheme.incomeAccent),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await vm.undoAutoAdd(item.id);
                if (context.mounted) {
                  ref
                      .read(appAlertProvider.notifier)
                      .show(
                        'Auto-added transaction undone',
                        tone: AppAlertTone.success,
                      );
                }
              },
              child: const Text('Undo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No captured transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'When your bank sends an SMS notification after a transaction, it will appear here for review.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
