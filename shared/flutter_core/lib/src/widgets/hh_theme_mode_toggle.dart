import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// Three-way colour-theme control — Light, Dark, or follow the device.
///
/// All three are shown at once rather than cycled through one button, so
/// "System" is discoverable and the current choice is readable without
/// interacting with it.
class HHThemeModeToggle extends StatelessWidget {
  const HHThemeModeToggle({super.key, required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = <(ThemeMode, String, IconData)>[
    (ThemeMode.light, 'Light', Icons.light_mode_outlined),
    (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
    (ThemeMode.system, 'System', Icons.smartphone_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    // Wraps rather than overflowing — three labelled options do not fit
    // across a navigation drawer at its narrowest.
    return Wrap(
      spacing: HHSpacing.space2,
      runSpacing: HHSpacing.space2,
      children: [
        for (final (value, label, icon) in _options)
          _Option(
            label: label,
            icon: icon,
            selected: mode == value,
            onTap: () => onChanged(value),
          ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? context.hh.textInverse : context.hh.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HHRadii.control),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: HHSpacing.space4,
            vertical: HHSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: selected ? context.hh.actionPrimary : context.hh.surfaceSunken,
            borderRadius: BorderRadius.circular(HHRadii.control),
            border: Border.all(
              color: selected ? context.hh.actionPrimary : context.hh.borderDefault,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: HHSpacing.space2),
              Text(
                label,
                style: TextStyle(
                  fontSize: HHTypeScale.textSm,
                  fontWeight: selected ? HHTypeScale.weightSemibold : HHTypeScale.weightRegular,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
