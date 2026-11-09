import 'package:flutter/material.dart';
import '../../core/theme/spring_curves.dart';

/// An Apple-grade physics-animated gradient progress bar that smoothly
/// responds to changes with critically damped spring curves and health-based gradients.
class SpringProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0 (or > 1.0 for over-budget)
  final double height;
  final Color? backgroundColor;
  final Gradient? customGradient;

  const SpringProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.backgroundColor,
    this.customGradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final clampedValue = value.clamp(0.0, 1.0);
    final isOver = value > 1.0;
    final isWarning = value >= 0.8 && !isOver;

    final defaultBg = backgroundColor ??
        (isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5));

    final effectiveGradient = customGradient ??
        (isOver
            ? const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFEF5350)],
              )
            : (isWarning
                ? const LinearGradient(
                    colors: [Color(0xFFF57F17), Color(0xFFFFB300)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF2E7A7D), Color(0xFF43A047)],
                  )));

    final borderRadius = BorderRadius.circular(height / 2);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: borderRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;

          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: SpringCurves.criticallyDamped,
            tween: Tween<double>(begin: 0.0, end: clampedValue),
            builder: (context, animValue, _) {
              final barWidth = totalWidth * animValue;

              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: barWidth,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: effectiveGradient,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: (isOver
                                ? const Color(0xFFE53935)
                                : (isWarning
                                    ? const Color(0xFFF57F17)
                                    : const Color(0xFF2E7A7D)))
                            .withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

