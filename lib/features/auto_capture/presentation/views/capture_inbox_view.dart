import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/app_currency.dart';
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
                      if (state.pendingItems.isNotEmpty) ...[
                        Text(
                          'Pending Review (${state.pendingItems.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...state.pendingItems.map(
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
    final amountColor = isExpense
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final isDuplicate = item.isPossibleDuplicate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDuplicate
              ? Colors.amber.shade700
              : theme.colorScheme.outlineVariant,
          width: isDuplicate ? 1.5 : 1.0,
        ),
      ),
      color: isDuplicate
          ? (theme.brightness == Brightness.dark
                ? Colors.amber.withAlpha(20)
                : const Color(0xFFFFFBEB))
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDuplicate) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.shade700.withAlpha(120),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Possible Duplicate • A similar transaction was already recorded around this time',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                Text(
                  '${isExpense ? '-' : '+'}${CurrencyFormatter.formatCents(item.amountCents, currency)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: amountColor,
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
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    await Navigator.of(context).push(
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
                  child: Text(isDuplicate ? 'Add Anyway' : 'Add'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    await vm.dismiss(item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Transaction dismissed'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () => vm.undoDismiss(item.id),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(isDuplicate ? 'Dismiss Duplicate' : 'Dismiss'),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'ignore') {
                      vm.ignoreSender(item.sender);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ignored all messages from ${item.sender}',
                          ),
                        ),
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
    CaptureItem item,
    CaptureInboxViewModel vm,
    AppCurrency currency,
  ) {
    final theme = Theme.of(context);
    final isExpense = item.type.isExpense;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.counterparty ?? 'Bank transaction'),
        subtitle: Text(
          '${item.sender} • ${DateFormatter.fullDate(item.occurredAt)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isExpense ? '-' : '+'}${CurrencyFormatter.formatCents(item.amountCents, currency)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpense
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                await vm.undoAutoAdd(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Auto-added transaction undone'),
                    ),
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
