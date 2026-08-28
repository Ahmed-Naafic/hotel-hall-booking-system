import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// A labeled text field styled from the shared design tokens (FE-00) —
/// `InputDecorationTheme` already carries the border/color tokens, so this
/// widget only adds the label/obscure/keyboard/validator conveniences every
/// auth form needs, never a second set of colors.
class HHTextField extends StatelessWidget {
  const HHTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.autofillHints,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      autofillHints: autofillHints,
      enabled: enabled,
      style: TextStyle(fontSize: HHTypeScale.textMd, color: HHColors.textBody),
      decoration: InputDecoration(labelText: label),
    );
  }
}
