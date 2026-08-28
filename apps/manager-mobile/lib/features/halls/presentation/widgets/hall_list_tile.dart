import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../data/hall_models.dart';

class HallListTile extends StatelessWidget {
  const HallListTile({super.key, required this.hall, required this.onTap});

  final Hall hall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final capacity = hall.capacity;
    final subtitle = capacity != null ? 'Capacity: $capacity' : 'Capacity not set';
    return Card(
      margin: const EdgeInsets.only(bottom: HHSpacing.space4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HHRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(HHSpacing.cardPad),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: HHColors.surfaceNavyTint,
                  borderRadius: BorderRadius.circular(HHRadii.control),
                ),
                child: Icon(Icons.meeting_room_outlined, color: HHColors.navy700),
              ),
              const SizedBox(width: HHSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hall.displayTitle,
                      style: TextStyle(fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.textMd),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textXs),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: HHColors.textSubtle),
            ],
          ),
        ),
      ),
    );
  }
}
