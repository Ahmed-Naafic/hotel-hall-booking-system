import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../data/hall_models.dart';
import '../../data/hall_repository.dart';

class HallListTile extends StatefulWidget {
  const HallListTile({
    super.key,
    required this.hall,
    required this.hotelId,
    required this.onTap,
  });

  final Hall hall;
  final String hotelId;
  final VoidCallback onTap;

  @override
  State<HallListTile> createState() => _HallListTileState();
}

class _HallListTileState extends State<HallListTile> {
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadImage());
  }

  Future<void> _loadImage() async {
    try {
      final media = await HallRepository(
        context.read<ApiClient>(),
      ).getMedia(hotelId: widget.hotelId, hallId: widget.hall.id);
      if (mounted && media.isNotEmpty) {
        setState(() => _imageUrl = media.first.url);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hall = widget.hall;
    final capacity = hall.capacity;
    final location =
        hall.profileData?['location']?.toString() ??
        hall.profileData?['area']?.toString();
    return Card(
      margin: const EdgeInsets.only(bottom: HHSpacing.space4),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(HHRadii.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(HHRadii.card),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 8,
                child: _imageUrl == null
                    ? const ColoredBox(
                        color: HHColors.navy100,
                        child: Center(
                          child: Icon(
                            Icons.meeting_room_outlined,
                            size: 48,
                            color: HHColors.navy500,
                          ),
                        ),
                      )
                    : Image.network(
                        _imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: HHColors.navy100,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(HHSpacing.space4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hall.displayTitle,
                          style: TextStyle(
                            fontWeight: HHTypeScale.weightSemibold,
                            fontSize: HHTypeScale.textLg,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: HHColors.actionAccent,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: HHColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (capacity != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: HHColors.navy100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$capacity',
                        style: const TextStyle(
                          color: HHColors.navy700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
