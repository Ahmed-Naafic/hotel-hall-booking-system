import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// The small tracked-caps section label used above each group of form
/// fields/content ("HOTEL INFORMATION", "HALL PHOTOS", "ADDITIONAL
/// INFORMATION"). Consolidates the identical private `_sectionHeader`
/// previously duplicated per-screen into one shared, token-driven widget.
class HHSectionLabel extends StatelessWidget {
  const HHSectionLabel(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: TextStyle(
        color: HHColors.textMuted,
        fontWeight: HHTypeScale.weightSemibold,
        fontSize: HHTypeScale.textXs,
        letterSpacing: 0.8,
      ),
    );
    if (trailing == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: HHSpacing.space4),
        child: text,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: HHSpacing.space4),
      child: Row(
        children: [Expanded(child: text), trailing!],
      ),
    );
  }
}
