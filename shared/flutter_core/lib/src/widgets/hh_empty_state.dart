import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import 'hh_primary_button.dart';

/// The icon + title + message (+ optional action) layout repeated across
/// every screen's empty/error state — consolidated here so "no data yet"
/// and "something went wrong" always look the same, styled entirely from
/// the shared design tokens (FE-00). Never itself decides what message to
/// show — the caller always supplies the exact copy (e.g. the server's own
/// `ApiException.message` for an error state), this widget only lays it
/// out consistently.
class HHEmptyState extends StatelessWidget {
  const HHEmptyState({
    super.key,
    required this.icon,
    this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
    this.iconColor,
  });

  final IconData icon;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HHSpacing.space7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor ?? HHColors.navy300, size: 40),
            const SizedBox(height: HHSpacing.space5),
            if (title != null) ...[
              Text(title!, style: HHTypography.displaySm, textAlign: TextAlign.center),
              const SizedBox(height: HHSpacing.space3),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textMd),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: HHSpacing.space6),
              HHPrimaryButton(label: actionLabel!, isLoading: isLoading, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
