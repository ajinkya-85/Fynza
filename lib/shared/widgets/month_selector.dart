import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/date_formatter.dart';
import 'frosted_container.dart';
import 'pressable_scale.dart';

/// An Apple-style floating frosted glass month selector with tactile haptics,
/// directional slide transitions, and physical swipe gestures.
class MonthSelector extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthSelector({
    super.key,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  State<MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<MonthSelector> {
  void _handlePrevious() {
    HapticFeedback.selectionClick();
    widget.onPrevious();
  }

  void _handleNext() {
    HapticFeedback.selectionClick();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -100) {
              // Swiped left -> next month
              _handleNext();
            } else if (details.primaryVelocity! > 100) {
              // Swiped right -> previous month
              _handlePrevious();
            }
          },
          child: FrostedContainer(
            borderRadius: 24,
            blur: 16,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            tintColor: isDark
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.65,
                  )
                : theme.colorScheme.secondaryContainer.withValues(alpha: 0.75),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.5),
              width: 1.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PressableScale(
                  targetScale: 0.88,
                  onPressed: _handlePrevious,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 22,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 130,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.center,
                        children: [...previousChildren, ?currentChild],
                      ),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.96, end: 1).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                                reverseCurve: Curves.easeInCubic,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        DateFormatter.monthYear(widget.selectedDate),
                        key: ValueKey(
                          DateTime(
                            widget.selectedDate.year,
                            widget.selectedDate.month,
                          ),
                        ),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
                PressableScale(
                  targetScale: 0.88,
                  onPressed: _handleNext,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
