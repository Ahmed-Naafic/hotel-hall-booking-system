import 'package:flutter/animation.dart';

/// Motion tokens, ported 1:1 from
/// `Hotel Hall Design System/tokens/motion.css` (FE-00). "Calm, no bounce:
/// hospitality motion is a door easing shut", matching the source file's
/// own comment.
abstract final class HHMotion {
  static const Duration durInstant = Duration(milliseconds: 80);
  static const Duration durFast = Duration(milliseconds: 140);
  static const Duration durBase = Duration(milliseconds: 220);
  static const Duration durSlow = Duration(milliseconds: 360);
  static const Duration durSlower = Duration(milliseconds: 600);

  /// `cubic-bezier(.2,.6,.2,1)`
  static const Curve easeStandard = Cubic(0.2, 0.6, 0.2, 1);

  /// `cubic-bezier(0,.6,.3,1)`
  static const Curve easeOut = Cubic(0, 0.6, 0.3, 1);

  /// `cubic-bezier(.5,0,1,.5)`
  static const Curve easeIn = Cubic(0.5, 0, 1, 0.5);

  /// `--lift-hover: translateY(-2px)` — the hover/press lift used by cards.
  static const double liftHoverDy = -2;

  /// `--press-scale: .985`
  static const double pressScale = 0.985;
}
