import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/manager_formatters.dart';
import '../../data/hall_models.dart';
import '../../data/hall_repository.dart';
import 'hall_form_screen.dart';

enum _LoadStatus { loading, ready, error }

/// Manager → My Hotel → Halls → Hall Details (HL2/HL3, `GET
/// /hotels/:hotelId/halls/:id`). Shows exactly what the backend returns —
/// no invented status/visibility field (Hall Management Technical Design
/// §6/§12 deliberately never returns one; see `HallRepository`'s own doc
/// comment).
class HallDetailsScreen extends StatefulWidget {
  const HallDetailsScreen({
    super.key,
    required this.hotelId,
    required this.hallId,
  });

  final String hotelId;
  final String hallId;

  @override
  State<HallDetailsScreen> createState() => _HallDetailsScreenState();
}

class _HallDetailsScreenState extends State<HallDetailsScreen> {
  _LoadStatus _status = _LoadStatus.loading;
  Hall? _hall;
  List<HallMedia> _photos = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _LoadStatus.loading);
    try {
      final repository = HallRepository(context.read<ApiClient>());
      final hall = await repository.getHall(
        hotelId: widget.hotelId,
        id: widget.hallId,
      );
      List<HallMedia> photos = const [];
      try {
        photos = await repository.getMedia(
          hotelId: widget.hotelId,
          hallId: widget.hallId,
        );
      } catch (_) {
        // Hall information remains usable when media storage is unavailable.
      }
      if (!mounted) return;
      setState(() {
        _hall = hall;
        _photos = photos;
        _status = _LoadStatus.ready;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _status = _LoadStatus.error;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _status = _LoadStatus.error;
      });
    }
  }

  Future<void> _openEdit() async {
    final hall = _hall;
    if (hall == null) return;
    final updated = await Navigator.of(context).push<Hall>(
      MaterialPageRoute(
        builder: (_) =>
            HallFormScreen(hotelId: widget.hotelId, existingHall: hall),
      ),
    );
    if (updated != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hall updated.')));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(
        title: Text(_hall?.displayTitle ?? 'Hall'),
        actions: [
          if (_status == _LoadStatus.ready)
            IconButton(
              onPressed: _openEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            ),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    switch (_status) {
      case _LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case _LoadStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(HHSpacing.space7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: HHColors.danger700, size: 32),
                const SizedBox(height: HHSpacing.space3),
                Text(
                  _errorMessage ?? 'Something went wrong.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: HHColors.textMuted),
                ),
                const SizedBox(height: HHSpacing.space5),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        );

      case _LoadStatus.ready:
        final hall = _hall!;
        final entries =
            (hall.profileData?.entries ??
                    const Iterable<MapEntry<String, dynamic>>.empty())
                .where(
                  (entry) =>
                      entry.value != null &&
                      entry.value.toString().trim().isNotEmpty,
                )
                .toList();
        return ListView(
          children: [
            if (_photos.isNotEmpty)
              SizedBox(
                height: 260,
                child: PageView.builder(
                  itemCount: _photos.length,
                  itemBuilder: (_, index) => Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _photos[index].url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: HHColors.navy100,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: HHColors.surfaceOverlay,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${index + 1} / ${_photos.length}',
                            style: const TextStyle(color: HHColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(
                height: 180,
                child: ColoredBox(
                  color: HHColors.navy100,
                  child: Center(
                    child: Icon(
                      Icons.meeting_room_outlined,
                      size: 64,
                      color: HHColors.navy400,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(HHSpacing.space6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hall.displayTitle,
                          style: HHTypography.serifLg,
                        ),
                      ),
                      if (hall.capacity != null)
                        _Fact(
                          icon: Icons.groups_outlined,
                          value: '${hall.capacity}',
                          label: 'Guests',
                        ),
                    ],
                  ),
                  const SizedBox(height: HHSpacing.space7),
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: HHTypeScale.eyebrowSize,
                      letterSpacing: 1,
                      fontWeight: HHTypeScale.eyebrowWeight,
                      color: HHColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: HHSpacing.space3),
                  if (entries.isEmpty)
                    Text(
                      'No profile information yet.',
                      style: TextStyle(color: HHColors.textMuted),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(HHSpacing.cardPad),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final entry in entries)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: HHSpacing.space3,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ManagerFormatters.label(entry.key),
                                      style: TextStyle(
                                        color: HHColors.textMuted,
                                        fontSize: HHTypeScale.textXs,
                                      ),
                                    ),
                                    Text(
                                      entry.value?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: HHTypeScale.textMd,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: HHSpacing.space7),
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: HHTypeScale.eyebrowSize,
                      letterSpacing: 1,
                      fontWeight: HHTypeScale.eyebrowWeight,
                      color: HHColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: HHSpacing.space3),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(HHSpacing.cardPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created ${ManagerFormatters.date(hall.createdAt)}',
                            style: TextStyle(
                              color: HHColors.textMuted,
                              fontSize: HHTypeScale.textSm,
                            ),
                          ),
                          const SizedBox(height: HHSpacing.space2),
                          Text(
                            'Last updated ${ManagerFormatters.date(hall.updatedAt)}',
                            style: TextStyle(
                              color: HHColors.textMuted,
                              fontSize: HHTypeScale.textSm,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: HHColors.surfaceNavyTint,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: HHColors.navy700),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: HHColors.navy700,
          ),
        ),
      ],
    ),
  );
}
