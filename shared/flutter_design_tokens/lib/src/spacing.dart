/// Spacing tokens, ported 1:1 from
/// `Hotel Hall Design System/tokens/spacing.css` (FE-00). A 4px base scale,
/// with a 6px half-step used in control padding — matching the source
/// file's own comment.
abstract final class HHSpacing {
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 6;
  static const double space3 = 8;
  static const double space4 = 12;
  static const double space5 = 16;
  static const double space6 = 20;
  static const double space7 = 24;
  static const double space8 = 32;
  static const double space9 = 40;
  static const double space10 = 48;
  static const double space11 = 64;
  static const double space12 = 80;
  static const double space13 = 104;
  static const double space14 = 128;

  // Layout
  static const double containerMax = 1200;
  static const double containerNarrow = 760;
  static const double gutter = 24;
  static const double gutterLg = 40;
  static const double sectionY = space13;
  static const double sectionYTight = space11;

  // Control metrics
  static const double controlHSm = 32;
  static const double controlHMd = 40;
  static const double controlHLg = 48;
  static const double controlPadX = 18;
  static const double controlGap = 8;
  static const double cardPad = 20;
  static const double cardPadLg = 28;
}
