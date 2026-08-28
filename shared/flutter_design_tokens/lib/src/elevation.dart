import 'package:flutter/widgets.dart';

/// Elevation/shadow tokens, ported from
/// `Hotel Hall Design System/tokens/elevation.css` (FE-00). Shadows are
/// navy-tinted, never neutral black, matching the source file's own
/// comment. The CSS file's inset shadow, scrim gradients, and glass blur
/// are page-background/decoration concerns without a direct `BoxShadow`
/// equivalent — deliberately not ported here; add them additively if a
/// future screen genuinely needs them (`architecture-principles.md` §2).
abstract final class HHElevation {
  static const List<BoxShadow> xs = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color.fromRGBO(12, 42, 78, 0.06)),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color.fromRGBO(12, 42, 78, 0.08)),
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color.fromRGBO(12, 42, 78, 0.04)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 14, color: Color.fromRGBO(12, 42, 78, 0.10)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(offset: Offset(0, 12), blurRadius: 32, color: Color.fromRGBO(12, 42, 78, 0.14)),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(offset: Offset(0, 24), blurRadius: 60, color: Color.fromRGBO(12, 42, 78, 0.18)),
  ];

  /// `box-shadow: 0 0 0 3px rgba(34,146,158,.32)` — the focus ring.
  static const List<BoxShadow> focus = [
    BoxShadow(offset: Offset.zero, blurRadius: 0, spreadRadius: 3, color: Color.fromRGBO(34, 146, 158, 0.32)),
  ];

  static const List<BoxShadow> card = sm;
  static const List<BoxShadow> cardHover = md;
  static const List<BoxShadow> modal = xl;
}
