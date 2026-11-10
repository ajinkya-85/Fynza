import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/app_currency.dart';
import '../../../../shared/models/category_spending.dart';
import '../../../../shared/widgets/category_icon.dart';

class SpendingOverviewCard extends ConsumerWidget {
  final List<CategorySpending> spendings;
  final int totalExpenseCents;
  final VoidCallback onDetails;

  const SpendingOverviewCard({
    super.key,
    required this.spendings,
    required this.totalExpenseCents,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(selectedCurrencyProvider);
    final isDark = theme.brightness == Brightness.dark;
    final visibleSpendings = spendings.take(4).toList();
    final remainingSpendings = spendings.skip(4).toList();
    final visibleTotal = visibleSpendings.fold<int>(
      0,
      (total, item) => total + item.totalCents,
    );
    final surface = isDark
        ? theme.colorScheme.surfaceContainerLow
        : AppTheme.cardWhite;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.25)
              : AppTheme.borderCream,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppTheme.primaryAmber.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spending Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              TextButton(
                onPressed: onDetails,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryAmber,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Detail'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (spendings.isEmpty || totalExpenseCents <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'No spending recorded for this month',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : AppTheme.textTaupe,
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          // Keep the overview purely informational; no chart touch handlers.
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 31,
                          sections: spendings
                              .map(
                                (item) => PieChartSectionData(
                                  color: Color(item.category.color),
                                  value: item.totalCents.toDouble(),
                                  title: '',
                                  radius: 19,
                                ),
                              )
                              .toList(),
                        ),
                        duration: Duration.zero,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CurrencyFormatter.formatCents(
                              totalExpenseCents,
                              currency,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Total',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? theme.colorScheme.onSurfaceVariant
                                  : AppTheme.textTaupe,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in visibleSpendings)
                        _OverviewLegendRow(
                          name: item.category.name,
                          color: Color(item.category.color),
                          totalCents: item.totalCents,
                          percent: item.totalCents / totalExpenseCents * 100,
                          currency: currency,
                        ),
                      if (remainingSpendings.isNotEmpty)
                        _OverviewLegendRow(
                          name: 'Others',
                          color: isDark
                              ? theme.colorScheme.outline
                              : AppTheme.textTaupe.withValues(alpha: 0.6),
                          totalCents: totalExpenseCents - visibleTotal,
                          percent:
                              (totalExpenseCents - visibleTotal) /
                              totalExpenseCents *
                              100,
                          currency: currency,
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OverviewLegendRow extends StatelessWidget {
  final String name;
  final Color color;
  final int totalCents;
  final double percent;
  final AppCurrency currency;

  const _OverviewLegendRow({
    required this.name,
    required this.color,
    required this.totalCents,
    required this.percent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            CurrencyFormatter.formatCents(totalCents, currency),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class SpendingPieChart extends ConsumerWidget {
  final List<CategorySpending> spendings;
  final int totalExpenseCents;

  const SpendingPieChart({
    super.key,
    required this.spendings,
    required this.totalExpenseCents,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(selectedCurrencyProvider);
    final cardBg = isDark
        ? theme.colorScheme.surfaceContainerLow
        : AppTheme.cardWhite;
    final cardBorder = isDark
        ? theme.colorScheme.outlineVariant.withValues(alpha: 0.25)
        : AppTheme.borderCream;

    if (spendings.isEmpty || totalExpenseCents <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : AppTheme.primaryAmber.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? theme.colorScheme.surfaceContainerHighest
                              : AppTheme.scaffoldCream)
                          .withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.donut_large_rounded,
                  size: 32,
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : AppTheme.textTaupe.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No spending recorded for this month',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : AppTheme.textTaupe,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppTheme.primaryAmber.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 195,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    // The breakdown chart and category rows are intentionally non-interactive.
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2.5,
                    centerSpaceRadius: 48,
                    sections: spendings
                        .map(
                          (item) => PieChartSectionData(
                            color: Color(item.category.color),
                            value: item.totalCents.toDouble(),
                            title: '',
                            radius: 54,
                          ),
                        )
                        .toList(),
                  ),
                  duration: Duration.zero,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Spent',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : AppTheme.textTaupe,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatCents(
                        totalExpenseCents,
                        currency,
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: spendings.length,
            separatorBuilder: (_, _) => Divider(
              height: 12,
              color: isDark
                  ? theme.colorScheme.outlineVariant.withValues(alpha: 0.15)
                  : AppTheme.borderCream.withValues(alpha: 0.7),
            ),
            itemBuilder: (context, index) {
              final item = spendings[index];
              final percentage = item.totalCents / totalExpenseCents * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    CategoryIcon(
                      iconKey: item.category.icon,
                      colorValue: item.category.color,
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : AppTheme.textTaupe,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      CurrencyFormatter.formatCents(item.totalCents, currency),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
