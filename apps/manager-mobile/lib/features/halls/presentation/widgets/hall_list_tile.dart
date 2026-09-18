import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../../../core/presentation/manager_formatters.dart';
import '../../data/hall_models.dart';

class HallListTile extends StatelessWidget {
  const HallListTile({
    super.key,
    required this.hall,
    required this.onTap,
    this.onEdit,
    this.onToggleActive,
  });

  final Hall hall;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  /// The Manager's own Active/Inactive toggle — omitted (as `onEdit` above)
  /// wherever this tile isn't the Manager's own management view.
  final ValueChanged<bool>? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final capacity = hall.capacity;
    final location = hall.location;
    final photoUrl = hall.photos.isNotEmpty ? hall.photos.first.url : null;
    final rentAmountCents = hall.rentAmountCents;
    final rentDurationHours = hall.rentDurationHours;

    return Padding(
      padding: const EdgeInsets.only(bottom: HHSpacing.space4),
      child: HHCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        // `IntrinsicHeight` + `stretch` so the photo fills the row's full
        // height (whatever the text side naturally needs) — matching the
        // reference design, where the photo bleeds flush to the card's
        // left/top/bottom edges instead of sitting padded/inset like a
        // small square icon.
        child: Stack(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(HHRadii.card),
                      bottomLeft: Radius.circular(HHRadii.card),
                    ),
                    child: SizedBox(
                      width: 104,
                      child: HHNetworkImage(
                        url: photoUrl,
                        width: 104,
                        // Square corners here — the outer ClipRRect above is
                        // what shapes the visible (left-only) rounding.
                        borderRadius: 0,
                        fallbackIcon: Icons.meeting_room_outlined,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      // Extra headroom on the right (cardPad + 28) so the
                      // corner-anchored ⋮/chevron below never overlaps the
                      // Hall name.
                      padding: const EdgeInsets.fromLTRB(
                        HHSpacing.cardPad,
                        HHSpacing.cardPad,
                        HHSpacing.cardPad + 28,
                        HHSpacing.cardPad,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hall.displayTitle,
                            style: TextStyle(
                              fontWeight: HHTypeScale.weightSemibold,
                              fontSize: HHTypeScale.textMd,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: HHSpacing.space2),
                          // Capacity and price share one line (matching the
                          // reference design's "Capacity: 500 • $800 / day")
                          // instead of separate icon chips that could wrap
                          // onto their own lines and inflate the card's
                          // height.
                          Text(
                            [
                              capacity != null ? 'Capacity $capacity' : 'Capacity not set',
                              if (rentAmountCents != null)
                                '${ManagerFormatters.moneyCents(rentAmountCents)} / '
                                    '${rentDurationHours == 24 ? 'day' : '${rentDurationHours ?? 24}h'}',
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: capacity != null ? context.hh.textMuted : context.hh.textSubtle,
                              fontSize: HHTypeScale.textXs,
                            ),
                          ),
                          if (location != null) ...[
                            const SizedBox(height: HHSpacing.space1),
                            _MetaChip(icon: Icons.place_outlined, label: location),
                          ],
                          const SizedBox(height: HHSpacing.space2),
                          HHStatusBadge(
                            label: hall.isActive ? 'Active' : 'Inactive',
                            tone: hall.isActive
                                ? HHBadgeTone.success
                                : HHBadgeTone.warning,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Corner-anchored, matching the reference design — not inline
            // with the title (that read as floating "in the middle" of the
            // card rather than pinned to a corner).
            Positioned(
              top: HHSpacing.space1,
              right: HHSpacing.space1,
              child: onEdit != null
                  ? PopupMenuButton<String>(
                      tooltip: 'More actions',
                      icon: Icon(Icons.more_vert, color: context.hh.textSubtle),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (onToggleActive != null)
                          PopupMenuItem(
                            value: 'toggleActive',
                            child: ListTile(
                              leading: Icon(
                                hall.isActive
                                    ? Icons.toggle_off_outlined
                                    : Icons.toggle_on_outlined,
                              ),
                              title: Text(hall.isActive ? 'Deactivate' : 'Activate'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') onEdit!();
                        if (value == 'toggleActive') onToggleActive!(!hall.isActive);
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.all(HHSpacing.space3),
                      child: Icon(Icons.chevron_right, color: context.hh.textSubtle),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = context.hh.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: HHTypeScale.textXs),
        ),
      ],
    );
  }
}
