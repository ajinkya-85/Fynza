import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/spring_curves.dart';
import 'pressable_scale.dart';

/// An Apple-style fluid segmented slider control with a spring-animated sliding pill,
/// tactile selection haptics, and zero input latency.
class FluidSegmentedControl<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final ValueChanged<T> onSelectedItemChanged;
  final String Function(T item) labelBuilder;
  final IconData? Function(T item)? iconBuilder;
  final EdgeInsetsGeometry padding;

  const FluidSegmentedControl({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onSelectedItemChanged,
    required this.labelBuilder,
    this.iconBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedIndex = items.indexOf(selectedItem as T);

    return Padding(
      padding: padding,
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth) / items.length;

            return Stack(
              children: [
                // Animated sliding background pill
                if (selectedIndex >= 0)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: SpringCurves.criticallyDamped,
                    left: selectedIndex * itemWidth,
                    top: 0,
                    bottom: 0,
                    width: itemWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerLowest
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Interactive Segment Items
                Row(
                  children: items.map((item) {
                    final isSelected = item == selectedItem;
                    final icon = iconBuilder?.call(item);

                    return Expanded(
                      child: PressableScale(
                        targetScale: 0.94,
                        enableHaptics: false,
                        onPressed: () {
                          if (!isSelected) {
                            HapticFeedback.selectionClick();
                            onSelectedItemChanged(item);
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          color: Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icon != null) ...[
                                Icon(
                                  icon,
                                  size: 16,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                labelBuilder(item),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface)
                                      : theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

