import 'package:flutter/material.dart';

/// A widget that applies a soft, Apple-style top and bottom fading edge gradient mask
/// to its scrolling [child] so content smoothly dissolves rather than abruptly clipping.
class FadingScrollBoundary extends StatefulWidget {
  final Widget child;
  final double fadeHeight;

  const FadingScrollBoundary({
    super.key,
    required this.child,
    this.fadeHeight = 28.0,
  });

  @override
  State<FadingScrollBoundary> createState() => _FadingScrollBoundaryState();
}

class _FadingScrollBoundaryState extends State<FadingScrollBoundary> {
  double _topFade = 0.0;
  double _bottomFade = 1.0;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      final metrics = notification.metrics;
      final maxScroll = metrics.maxScrollExtent;
      final currentScroll = metrics.pixels;

      double newTopFade = 0.0;
      double newBottomFade = 0.0;

      if (maxScroll > 0) {
        // Top fade activates as user scrolls down from the top edge
        newTopFade = (currentScroll / widget.fadeHeight).clamp(0.0, 1.0);
        // Bottom fade stays active until approaching the end of the scroll range
        final remaining = maxScroll - currentScroll;
        newBottomFade = (remaining / widget.fadeHeight).clamp(0.0, 1.0);
      }

      if ((newTopFade - _topFade).abs() > 0.02 ||
          (newBottomFade - _bottomFade).abs() > 0.02) {
        setState(() {
          _topFade = newTopFade;
          _bottomFade = newBottomFade;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          if (bounds.height <= 0) {
            return const LinearGradient(colors: [Colors.black, Colors.black])
                .createShader(bounds);
          }

          final topRatio = (widget.fadeHeight * _topFade) / bounds.height;
          final bottomRatio =
              1.0 - ((widget.fadeHeight * _bottomFade) / bounds.height);

          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 1.0 - _topFade),
              Colors.black,
              Colors.black,
              Colors.black.withValues(alpha: 1.0 - _bottomFade),
            ],
            stops: [
              0.0,
              topRatio.clamp(0.0, 0.4),
              bottomRatio.clamp(0.6, 1.0),
              1.0,
            ],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: widget.child,
      ),
    );
  }
}

