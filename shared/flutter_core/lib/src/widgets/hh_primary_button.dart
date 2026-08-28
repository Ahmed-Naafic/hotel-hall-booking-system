import 'package:flutter/material.dart';

/// A full-width primary action button with a built-in loading spinner —
/// every auth form's submit button needs identical loading behavior
/// (`ElevatedButtonTheme` already carries the token-driven colors/shape
/// from FE-00; this widget only adds the loading state).
class HHPrimaryButton extends StatelessWidget {
  const HHPrimaryButton({super.key, required this.label, required this.onPressed, this.isLoading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Text(label),
    );
  }
}
