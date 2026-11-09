import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/models/transaction_with_category.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/money_text.dart';
import '../../../../shared/widgets/pressable_scale.dart';

/// An Apple-style transaction list tile with immediate touch-down press feedback,
/// squircle curvature, and optical typography.
class TransactionTile extends StatelessWidget {
  final TransactionWithCategory item;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transaction = item.transaction;
    final category = item.category;

    return PressableScale(
      targetScale: 0.985,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            CategoryIcon(
              iconKey: category.icon,
              colorValue: category.color,
              size: 44,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        DateFormatter.relativeDate(transaction.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (transaction.note != null &&
                          transaction.note!.trim().isNotEmpty) ...[
                        Text(
                          ' • ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            transaction.note!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            MoneyText(
              cents: transaction.amount,
              type: transaction.type,
              showSign: true,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
