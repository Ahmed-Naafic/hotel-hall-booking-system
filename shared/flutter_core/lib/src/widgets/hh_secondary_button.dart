import 'package:flutter/material.dart';

/// The outlined counterpart to [HHPrimaryButton] — same loading-state API,
/// styled entirely from `OutlinedButtonThemeData` (FE-00), for secondary
/// actions (Retry, Edit, Add Photos) that shouldn't compete visually with
/// a screen's one primary action.
class HHSecondaryButton extends StatelessWidget {
  const HHSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : Text(label);

    if (icon == null) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      );
    }
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
