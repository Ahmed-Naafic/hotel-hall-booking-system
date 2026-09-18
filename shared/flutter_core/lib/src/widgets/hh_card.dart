import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// A rounded, subtly-elevated content container — the standard card shell
/// used across every Manager Mobile screen (status cards, onboarding
/// steps, form sections, list tiles) instead of each screen hand-rolling
/// its own `Container`/`Card` decoration. Styled entirely from the shared
/// design tokens (FE-00); never a screen-local color/radius/shadow.
class HHCard extends StatelessWidget {
  const HHCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(HHSpacing.cardPad),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? context.hh.surfaceCard,
        borderRadius: BorderRadius.circular(HHRadii.card),
        boxShadow: HHElevation.card,
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(HHRadii.card),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(HHRadii.card),
                child: Padding(padding: padding, child: child),
              ),
            ),
    );
    return card;
  }
}
