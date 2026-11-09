import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../core/theme/spring_curves.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/category_spending.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/pressable_scale.dart';

/// Apple-style interactive spending breakdown chart featuring spring slice expansions,
/// tactile selection haptics, dynamic center focus, and interactive legend rows.
class SpendingPieChart extends ConsumerStatefulWidget {
  final List<CategorySpending> spendings;
  final int totalExpenseCents;

  const SpendingPieChart({
    super.key,
    required this.spendings,
    required this.totalExpenseCents,
  });

  @override
  ConsumerState<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends ConsumerState<SpendingPieChart> {
  int _touchedIndex = -1;

  void _onSectionTouched(int newIndex) {
    if (_touchedIndex != newIndex) {
      if (newIndex >= 0) {
        HapticFeedback.selectionClick();
      }
      setState(() {
        _touchedIndex = newIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = ref.watch(selectedCurrencyProvider);

    if (widget.spendings.isEmpty || widget.totalExpenseCents <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.donut_large_rounded,
                  size: 32,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No spending recorded for this month',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasSelection =
        _touchedIndex >= 0 && _touchedIndex < widget.spendings.length;
    final selectedItem = hasSelection ? widget.spendings[_touchedIndex] : null;

    final sections = widget.spendings.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 66.0 : 54.0;

      return PieChartSectionData(
        color: Color(item.category.color),
        value: item.totalCents.toDouble(),
        title: '',
        radius: radius,
        badgeWidget: isTouched
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              if (hasSelection)
                TextButton(
                  onPressed: () => _onSectionTouched(-1),
                  child: const Text('Reset'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 195,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _onSectionTouched(-1);
                          return;
                        }
                        _onSectionTouched(
                          pieTouchResponse.touchedSection!.touchedSectionIndex,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2.5,
                    centerSpaceRadius: 48,
                    sections: sections,
                  ),
                ),
                // Center dynamic focus with animated switcher
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: SpringCurves.criticallyDamped,
                  switchOutCurve: SpringCurves.criticallyDamped,
                  child: selectedItem != null
                      ? Column(
                          key: ValueKey('selected_${selectedItem.category.id}'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedItem.category.name,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatCents(
                                selectedItem.totalCents,
                                currency,
                              ),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('total_spent'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total Spent',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatCents(
                                widget.totalExpenseCents,
                                currency,
                              ),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Category legend list with tap-to-focus
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.spendings.length,
            separatorBuilder: (_, _) => const Divider(height: 10),
            itemBuilder: (context, index) {
              final item = widget.spendings[index];
              final isSelected = index == _touchedIndex;
              final percentage =
                  (item.totalCents / widget.totalExpenseCents) * 100;

              return PressableScale(
                targetScale: 0.985,
                onPressed: () {
                  _onSectionTouched(isSelected ? -1 : index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CategoryIcon(
                        iconKey: item.category.icon,
                        colorValue: item.category.color,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.category.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        CurrencyFormatter.formatCents(item.totalCents, currency),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
