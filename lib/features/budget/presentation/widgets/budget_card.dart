import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/budget_overview.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../../shared/widgets/spring_progress_bar.dart';

class BudgetCard extends ConsumerWidget {
  final BudgetOverview overview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BudgetCard({
    super.key,
    required this.overview,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(selectedCurrencyProvider);
    final category = overview.category;
    final budget = overview.budget;
    final progress = overview.progress;
    final isOver = overview.isOverBudget;
    final percentInt = (progress * 100).toInt();

    final statusColor = isOver
        ? theme.colorScheme.error
        : (progress >= 0.8 ? const Color(0xFFF57F17) : const Color(0xFF2E7A7D));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(category.color).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: CategoryIcon(
                  iconKey: category.icon,
                  colorValue: category.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOver
                          ? 'Over budget by ${CurrencyFormatter.formatCents(overview.spentCents - budget.amountLimit, currency)}'
                          : '${CurrencyFormatter.formatCents(overview.remainingCents, currency)} remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOver
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isOver ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOver ? 'Over Limit' : '$percentInt%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (onEdit != null)
                PressableScale(
                  targetScale: 0.88,
                  enableHaptics: false,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onEdit?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (onDelete != null)
                PressableScale(
                  targetScale: 0.88,
                  enableHaptics: false,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onDelete?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Physics-animated gradient progress bar
          SpringProgressBar(
            value: progress,
            height: 9,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyFormatter.formatCents(overview.spentCents, currency)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
              Text(
                'Limit: ${CurrencyFormatter.formatCents(budget.amountLimit, currency)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
