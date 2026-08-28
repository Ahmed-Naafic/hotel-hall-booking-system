import 'package:flutter/widgets.dart';

/// Radius tokens, ported 1:1 from
/// `Hotel Hall Design System/tokens/radii.css` (FE-00). "Soft,
/// hospitality-warm rounding — never pill-shaped except tags/avatars",
/// matching the source file's own comment.
abstract final class HHRadii {
  static const double none = 0;
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 10;
  static const double xl = 14;
  static const double xl2 = 20;
  static const double pill = 999;

  static const double card = lg;
  static const double control = md;
  static const double image = lg;
  static const double modal = xl;

  /// The signature "arch" shape lifted from the logo's venue archway —
  /// `--arch-top: 120px 120px var(--radius-sm) var(--radius-sm)` in the
  /// source CSS (top corners heavily rounded, bottom corners `--radius-sm`).
  static const BorderRadius archTop = BorderRadius.only(
    topLeft: Radius.circular(120),
    topRight: Radius.circular(120),
    bottomLeft: Radius.circular(sm),
    bottomRight: Radius.circular(sm),
  );
}
