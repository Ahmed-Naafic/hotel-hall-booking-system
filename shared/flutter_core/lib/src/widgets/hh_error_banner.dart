import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// Displays an API/validation error message inline in a form — always the
/// server's own `message` text (`ApiException.message`), never a
/// re-worded/invented one.
class HHErrorBanner extends StatelessWidget {
  const HHErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: HHSpacing.space4, vertical: HHSpacing.space3),
      margin: const EdgeInsets.only(bottom: HHSpacing.space4),
      decoration: BoxDecoration(
        color: HHColors.danger100,
        borderRadius: BorderRadius.circular(HHRadii.control),
        border: Border.all(color: HHColors.danger500.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: HHColors.danger700, size: 20),
          const SizedBox(width: HHSpacing.space3),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: HHColors.danger700, fontSize: HHTypeScale.textSm),
            ),
          ),
        ],
      ),
    );
  }
}
