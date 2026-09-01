import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// A purely visual tone — this widget has no opinion on which Hotel/Hall
/// status maps to which tone. The caller (the screen that actually knows
/// the domain meaning of a given status string) decides that; this widget
/// never encodes lifecycle/business meaning itself.
enum HHBadgeTone { neutral, info, success, warning, danger }

/// A small pill-shaped status label — displays the backend's own status
/// string verbatim (never re-worded/invented), colored by [tone] using
/// only the shared semantic color tokens (FE-00).
class HHStatusBadge extends StatelessWidget {
  const HHStatusBadge({super.key, required this.label, this.tone = HHBadgeTone.neutral});

  final String label;
  final HHBadgeTone tone;

  (Color, Color) _colors() {
    switch (tone) {
      case HHBadgeTone.success:
        return (HHColors.success100, HHColors.success700);
      case HHBadgeTone.warning:
        return (HHColors.warning100, HHColors.warning700);
      case HHBadgeTone.danger:
        return (HHColors.danger100, HHColors.danger700);
      case HHBadgeTone.info:
        return (HHColors.info100, HHColors.info700);
      case HHBadgeTone.neutral:
        return (HHColors.surfaceSunken, HHColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: HHSpacing.space4, vertical: HHSpacing.space2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(HHRadii.pill)),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.textXs),
      ),
    );
  }
}
