import 'package:flutter/animation.dart';

/// Apple-grade fluid spring definitions and curves based on WWDC Designing Fluid Interfaces.
class SpringCurves {
  SpringCurves._();

  /// Default critically damped spring (damping ratio = 1.0).
  /// Settle time approx 350ms, zero overshoot.
  static const SpringDescription defaultSpring = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 26.83, // 2 * sqrt(1.0 * 180.0) ≈ 26.83 -> damping ratio = 1.0
  );

  /// Snappy spring for quick micro-interactions like toggles and chips (approx 250ms).
  static const SpringDescription snappySpring = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 34.64, // damping ratio = 1.0
  );

  /// Underdamped momentum/flick spring with slight physical bounce (damping ratio ≈ 0.8).
  /// Reserved for momentum-driven releases and flick gestures.
  static const SpringDescription momentumSpring = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 21.46, // damping ratio ≈ 0.8
  );

  /// Sheet and modal presentation spring (approx 400ms).
  static const SpringDescription sheetSpring = SpringDescription(
    mass: 1.0,
    stiffness: 160.0,
    damping: 22.0, // damping ratio ≈ 0.87
  );

  /// Critically damped ease-out curve (mimics damping = 1.0 with swift onset and smooth settle).
  static const Curve criticallyDamped = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Snappy touch-down curve for instant response on press.
  static const Curve touchDown = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Gentle physical rebound curve on release.
  static const Curve rebound = Cubic(0.2, 1.0, 0.3, 1.0);
}

