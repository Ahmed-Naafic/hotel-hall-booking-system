import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import 'hh_gold_button.dart';

/// A full-width primary action button with a built-in loading spinner —
/// every form's submit button needs identical loading behavior.
///
/// The fill follows the CTA role rather than one fixed colour: navy on a
/// light page, and in dark mode the gold treatment the approved login
/// design uses. Dark mode's page *is* navy, so a navy button there is a
/// shape you have to hunt for; gold is the only brand colour that carries
/// on both grounds. Screens get this automatically by using this widget —
/// none of them names a colour.
class HHPrimaryButton extends StatelessWidget {
  const HHPrimaryButton({super.key, required this.label, required this.onPressed, this.isLoading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return HHGoldButton(
        label: label,
        onPressed: onPressed,
        isLoading: isLoading,
        // No trailing arrow: that flourish belongs to the auth screens,
        // not to every Save/Confirm in the app.
        trailingIcon: null,
        // Keep the light theme's control height so a screen's layout does
        // not shift when the theme changes.
        height: HHSpacing.controlHMd,
      );
    }
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: context.hh.onActionCta),
            )
          : Text(label),
    );
  }
}
