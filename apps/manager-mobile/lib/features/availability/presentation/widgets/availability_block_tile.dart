import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../data/availability_models.dart';

/// Mogadishu is a fixed UTC+3 offset, no DST (Approved Technical Design
/// §4) — display always adds exactly 3 hours to the stored UTC instant,
/// never the device's own `.toLocal()` (which would show the Manager's own
/// timezone, not Mogadishu's).
String _mogadishuTimeLabel(DateTime utc) {
  final local = utc.toUtc().add(const Duration(hours: 3));
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class AvailabilityBlockTile extends StatelessWidget {
  const AvailabilityBlockTile({
    super.key,
    required this.block,
    required this.onTap,
    required this.onDelete,
  });

  final AvailabilityBlock block;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final reason = block.reason;
    return Padding(
      padding: const EdgeInsets.only(bottom: HHSpacing.space4),
      child: HHCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(HHSpacing.cardPad),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HHColors.surfaceNavyTint,
                  borderRadius: BorderRadius.circular(HHRadii.control),
                ),
                child: Icon(Icons.block_outlined, color: HHColors.navy700, size: 20),
              ),
              const SizedBox(width: HHSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_mogadishuTimeLabel(block.startsAt)} – ${_mogadishuTimeLabel(block.endsAt)}',
                      style: TextStyle(
                        fontWeight: HHTypeScale.weightSemibold,
                        fontSize: HHTypeScale.textMd,
                      ),
                    ),
                    if (reason != null && reason.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        reason,
                        style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textSm),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
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
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') onTap();
                  if (value == 'delete') onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
