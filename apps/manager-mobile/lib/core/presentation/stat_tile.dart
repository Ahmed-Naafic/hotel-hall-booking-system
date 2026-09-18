import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// A single labeled metric tile (icon, value, label), optionally tappable —
/// the Dashboard's Overview grid and [MyHotelScreen]'s own profile stats
/// both use this exact shape (`folder-structure.md` §5: two real consumers
/// justifies sharing it here rather than each screen keeping its own
/// private copy). `value` is always caller-resolved from real data (a
/// `FutureBuilder`'s snapshot, a loading ellipsis, or an error dash) — this
/// widget itself never fetches or invents anything.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HHCard(
      onTap: onTap,
      padding: const EdgeInsets.all(HHSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(HHRadii.control)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: HHSpacing.space3),
          Text(
            value,
            style: TextStyle(fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.text2xl),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textXs),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// The resolved display value for an [AsyncSnapshot]-backed [StatTile]:
/// the real value once known, an ellipsis while loading, or a dash on
/// error — never a fabricated placeholder number.
String statTileValueOf(AsyncSnapshot<Object?> snapshot, String? resolved) {
  if (resolved != null) return resolved;
  return snapshot.hasError ? '—' : '…';
}
