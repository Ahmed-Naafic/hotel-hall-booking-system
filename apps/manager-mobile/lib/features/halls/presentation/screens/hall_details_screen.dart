import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

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
  const HallDetailsScreen({super.key, required this.hotelId, required this.hallId});

  final String hotelId;
  final String hallId;

  @override
  State<HallDetailsScreen> createState() => _HallDetailsScreenState();
}

class _HallDetailsScreenState extends State<HallDetailsScreen> {
  _LoadStatus _status = _LoadStatus.loading;
  Hall? _hall;
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
      final hall = await repository.getHall(hotelId: widget.hotelId, id: widget.hallId);
      if (!mounted) return;
      setState(() {
        _hall = hall;
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
      MaterialPageRoute(builder: (_) => HallFormScreen(hotelId: widget.hotelId, existingHall: hall)),
    );
    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hall updated.')));
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
          if (_status == _LoadStatus.ready) IconButton(onPressed: _openEdit, icon: const Icon(Icons.edit_outlined), tooltip: 'Edit'),
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
                Text(_errorMessage ?? 'Something went wrong.', textAlign: TextAlign.center, style: TextStyle(color: HHColors.textMuted)),
                const SizedBox(height: HHSpacing.space5),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        );

      case _LoadStatus.ready:
        final hall = _hall!;
        final entries = hall.profileData?.entries.toList() ?? const [];
        return ListView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          children: [
            Text('Profile', style: TextStyle(fontSize: HHTypeScale.eyebrowSize, letterSpacing: 1, fontWeight: HHTypeScale.eyebrowWeight, color: HHColors.textMuted)),
            const SizedBox(height: HHSpacing.space3),
            if (entries.isEmpty)
              Text('No profile information yet.', style: TextStyle(color: HHColors.textMuted))
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(HHSpacing.cardPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: HHSpacing.space3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key, style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textXs)),
                              Text(entry.value?.toString() ?? '', style: TextStyle(fontSize: HHTypeScale.textMd)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: HHSpacing.space7),
            Text('Details', style: TextStyle(fontSize: HHTypeScale.eyebrowSize, letterSpacing: 1, fontWeight: HHTypeScale.eyebrowWeight, color: HHColors.textMuted)),
            const SizedBox(height: HHSpacing.space3),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(HHSpacing.cardPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Created ${hall.createdAt.toLocal()}', style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textSm)),
                    const SizedBox(height: HHSpacing.space2),
                    Text('Last updated ${hall.updatedAt.toLocal()}', style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textSm)),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}
