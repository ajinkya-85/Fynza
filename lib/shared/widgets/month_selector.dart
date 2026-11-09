import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/spring_curves.dart';
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
  bool _isForward = true;

  @override
  void didUpdateWidget(covariant MonthSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _isForward = widget.selectedDate.isAfter(oldWidget.selectedDate);
    }
  }

  void _handlePrevious() {
    setState(() => _isForward = false);
    HapticFeedback.selectionClick();
    widget.onPrevious();
  }

  void _handleNext() {
    setState(() => _isForward = true);
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
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65)
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
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
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: SpringCurves.criticallyDamped,
                      switchOutCurve: SpringCurves.criticallyDamped,
                      transitionBuilder: (child, animation) {
                        final inOffset = _isForward
                            ? const Offset(0.35, 0.0)
                            : const Offset(-0.35, 0.0);
                        final outOffset = _isForward
                            ? const Offset(-0.35, 0.0)
                            : const Offset(0.35, 0.0);

                        final slideAnim = Tween<Offset>(
                          begin: child.key == ValueKey(widget.selectedDate)
                              ? inOffset
                              : Offset.zero,
                          end: child.key == ValueKey(widget.selectedDate)
                              ? Offset.zero
                              : outOffset,
                        ).animate(animation);

                        return SlideTransition(
                          position: slideAnim,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        DateFormatter.monthYear(widget.selectedDate),
                        key: ValueKey(widget.selectedDate),
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
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
