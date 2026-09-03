import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../data/hall_models.dart';

class HallListTile extends StatelessWidget {
  const HallListTile({
    super.key,
    required this.hall,
    required this.onTap,
    this.onEdit,
  });

  final Hall hall;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final capacity = hall.capacity;
    final location = hall.location;
    final photoUrl = hall.photos.isNotEmpty ? hall.photos.first.url : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: HHSpacing.space4),
      child: HHCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(HHSpacing.cardPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: photoUrl != null
                    ? HHNetworkImage(
                        url: photoUrl,
                        width: 56,
                        height: 56,
                        fallbackIcon: Icons.meeting_room_outlined,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: HHColors.surfaceNavyTint,
                          borderRadius: BorderRadius.circular(HHRadii.control),
                        ),
                        child: Icon(
                          Icons.meeting_room_outlined,
                          color: HHColors.navy700,
                        ),
                      ),
              ),
              const SizedBox(width: HHSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Wrap(
                      spacing: HHSpacing.space4,
                      runSpacing: HHSpacing.space1,
                      children: [
                        if (capacity != null)
                          _MetaChip(
                            icon: Icons.groups_2_outlined,
                            label: 'Capacity $capacity',
                          )
                        else
                          _MetaChip(
                            icon: Icons.groups_2_outlined,
                            label: 'Capacity not set',
                            muted: true,
                          ),
                        if (location != null)
                          _MetaChip(
                            icon: Icons.place_outlined,
                            label: location,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                PopupMenuButton<String>(
                  tooltip: 'More actions',
                  icon: Icon(Icons.more_vert, color: HHColors.textSubtle),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  onSelected: (_) => onEdit!(),
                )
              else
                Icon(Icons.chevron_right, color: HHColors.textSubtle),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? HHColors.textSubtle : HHColors.textMuted;
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
