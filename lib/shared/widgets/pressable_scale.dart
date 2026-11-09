import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/spring_curves.dart';

/// An Apple-style interactive wrapper that scales down instantly on touch-down
/// and provides crisp, multi-modal tactile feedback.
///
/// Follows Apple WWDC Designing Fluid Interfaces:
/// - Immediate response on pointer down (not on tap release)
/// - Fluid spring-backed recovery
/// - Haptic harmony on press commit
/// - Smooth cancellation if dragged away
/// - Respects system reduced-motion settings
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double targetScale;
  final bool enableHaptics;
  final Duration pressDuration;
  final Duration releaseDuration;
  final HitTestBehavior behavior;

  const PressableScale({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.targetScale = 0.975,
    this.enableHaptics = true,
    this.pressDuration = const Duration(milliseconds: 100),
    this.releaseDuration = const Duration(milliseconds: 250),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<PressableScale> createState() => PressableScaleState();
}

class PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @visibleForTesting
  AnimationController get controller => _controller;

  @visibleForTesting
  Animation<double> get scaleAnimation => _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
      reverseDuration: widget.releaseDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.targetScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: SpringCurves.touchDown,
        reverseCurve: SpringCurves.rebound,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.onPressed == null && widget.onLongPress == null) return;
    _isPressed = true;

    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }

    _controller.forward();
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isPressed) return;
    _isPressed = false;

    _controller.reverse();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (!_isPressed) return;
    _isPressed = false;

    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (isReducedMotion || (widget.onPressed == null && widget.onLongPress == null)) {
      return GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onPressed,
        onLongPress: widget.onLongPress != null
            ? () {
                if (widget.enableHaptics) HapticFeedback.mediumImpact();
                widget.onLongPress!();
              }
            : null,
        child: widget.child,
      );
    }

    return Listener(
      behavior: widget.behavior,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onPressed,
        onLongPress: widget.onLongPress != null
            ? () {
                if (widget.enableHaptics) HapticFeedback.mediumImpact();
                widget.onLongPress!();
              }
            : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
