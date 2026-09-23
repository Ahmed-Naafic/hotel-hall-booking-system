import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// Three-icon reassurance row under the Login form — purely decorative
/// brand chrome (no backend data behind it), shared verbatim between apps
/// since neither Customer nor Hotel Manager copy differs here.
class AuthFeatureHighlights extends StatelessWidget {
  const AuthFeatureHighlights({super.key});

  static const _items = [
    (icon: Icons.event_available_rounded, label: 'Easy Booking'),
    (icon: Icons.shield_rounded, label: 'Secure & Reliable'),
    (icon: Icons.groups_rounded, label: 'Great Events'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final item in _items)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: context.hh.surfaceGoldTint,
                child: Icon(item.icon, color: context.hh.actionGold, size: 22),
              ),
              const SizedBox(height: HHSpacing.space2),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: HHTypeScale.textXs, color: context.hh.textMuted),
              ),
            ],
          ),
      ],
    );
  }
}

/// The Login screen's closing tagline — a hairline rule on either side of
/// "Your Events, Our Halls", echoing the wordmark's own eyebrow/rule motif
/// rather than inventing a second decorative device.
class AuthFooterTagline extends StatelessWidget {
  const AuthFooterTagline({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: Divider(color: context.hh.borderRuleGold, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HHSpacing.space4),
          child: Text(
            'Your Events, Our Halls',
            style: TextStyle(
              fontSize: HHTypeScale.textXs,
              color: context.hh.textGold,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.hh.borderRuleGold, thickness: 1)),
      ],
    );
  }
}
