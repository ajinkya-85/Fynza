import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/pressable_scale.dart';

/// Modern cute finance summary cards featuring tactile touch feedback,
/// side-by-side Blush Expense & Matcha Mint Income cards, and warm optical typography.
class SummaryCards extends ConsumerWidget {
  final int totalIncomeCents;
  final int totalExpenseCents;
  final int netBalanceCents;

  const SummaryCards({
    super.key,
    required this.totalIncomeCents,
    required this.totalExpenseCents,
    required this.netBalanceCents,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(selectedCurrencyProvider);

    final expenseCardBg = isDark
        ? const Color(0xFF331D1C)
        : AppTheme.expenseCardBg;
    final expenseCardBorder = isDark
        ? const Color(0xFF482725)
        : const Color(0xFFF9D5CF);
    final expenseTextColor = isDark
        ? const Color(0xFFFF8A80)
        : AppTheme.expenseAccent;

    final incomeCardBg = isDark
        ? const Color(0xFF162D20)
        : AppTheme.incomeCardBg;
    final incomeCardBorder = isDark
        ? const Color(0xFF1E3E2C)
        : const Color(0xFFD2EEDC);
    final incomeTextColor = isDark
        ? const Color(0xFF81C784)
        : AppTheme.incomeAccent;

    return Column(
      children: [
        // Main Net Balance Card with tactile press feedback and warm aesthetic
        PressableScale(
          targetScale: 0.985,
          onPressed: () {},
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerLow
                  : AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? theme.colorScheme.outlineVariant.withValues(alpha: 0.25)
                    : AppTheme.borderCream,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : AppTheme.primaryAmber.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAmber
                                .withValues(alpha: isDark ? 0.2 : 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppTheme.primaryAmber,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Net Balance',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isDark
                                ? theme.colorScheme.onSurfaceVariant
                                : AppTheme.textTaupe,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? theme.colorScheme.surfaceContainerHigh
                                : const Color(0xFFF7F2EB))
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'This Month',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? theme.colorScheme.onSurfaceVariant
                              : AppTheme.textTaupe,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  CurrencyFormatter.formatCents(netBalanceCents, currency),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? theme.colorScheme.onSurface
                        : AppTheme.textCharcoal,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Side-by-side Blush Expense & Matcha Mint Income Cards
        Row(
          children: [
            // Expense Card (Soft Rose Blush)
            Expanded(
              child: PressableScale(
                targetScale: 0.97,
                onPressed: () {},
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: expenseCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: expenseCardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: expenseTextColor
                                  .withValues(alpha: isDark ? 0.22 : 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              color: expenseTextColor,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Expense',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: expenseTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '-${CurrencyFormatter.formatCents(totalExpenseCents, currency)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: expenseTextColor,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Income Card (Matcha Mint)
            Expanded(
              child: PressableScale(
                targetScale: 0.97,
                onPressed: () {},
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: incomeCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: incomeCardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: incomeTextColor
                                  .withValues(alpha: isDark ? 0.22 : 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              color: incomeTextColor,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Income',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: incomeTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '+${CurrencyFormatter.formatCents(totalIncomeCents, currency)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: incomeTextColor,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
