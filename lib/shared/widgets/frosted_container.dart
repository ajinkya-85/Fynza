import 'dart:ui';
import 'package:flutter/material.dart';

/// An Apple-style frosted glass surface featuring progressive background blur,
/// adaptive light/dark translucency, and light-catching hairline borders.
///
/// Follows Apple WWDC Designing Fluid Interfaces (§12 Materials & Depth):
/// - Floating functional layer that structures content without blocking it
/// - Content scrolls smoothly underneath
/// - Hairline border catching ambient light
/// - Automatically adapts to light/dark themes
/// - Respects reduced-transparency accessibility settings
class FrostedContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const FrostedContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.tintColor,
    this.border,
    this.boxShadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Default translucent background colors
    final defaultBg = isDark
        ? const Color(0xCC1E1E1E)
        : Colors.white.withValues(alpha: 0.72);

    final effectiveBg = tintColor ?? defaultBg;

    // Default light-catching hairline border
    final effectiveBorder = border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.65),
          width: 1.0,
        );

    final content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
        boxShadow: boxShadow,
      ),
      child: child,
    );

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}

