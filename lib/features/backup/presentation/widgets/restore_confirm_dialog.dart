import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/fading_scroll_boundary.dart';
import '../../domain/models/backup_summary.dart';

class RestoreConfirmDialog extends StatelessWidget {
  final BackupSummary summary;
  final String fileName;
  final VoidCallback onConfirm;

  const RestoreConfirmDialog({
    super.key,
    required this.summary,
    required this.fileName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.yMMMd().add_jm().format(
      summary.createdAt.toLocal(),
    );

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          const Expanded(child: Text('Restore backup?')),
        ],
      ),
      content: FadingScrollBoundary(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Created: $dateStr',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _CountRow(
                      label: 'Transactions',
                      count: summary.transactionCount,
                      icon: Icons.receipt_long,
                    ),
                    const SizedBox(height: 6),
                    _CountRow(
                      label: 'Categories',
                      count: summary.categoryCount,
                      icon: Icons.category,
                    ),
                    const SizedBox(height: 6),
                    _CountRow(
                      label: 'Budgets',
                      count: summary.budgetCount,
                      icon: Icons.pie_chart,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will replace all current data. A safety copy of your current data will be saved first.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          child: const Text('Restore'),
        ),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _CountRow({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          '$count',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
