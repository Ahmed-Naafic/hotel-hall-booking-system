import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../data/hall_models.dart';
import '../../data/hall_repository.dart';
import 'hall_form_screen.dart';

enum _LoadStatus { loading, ready, error }

/// The Hall's own named standard fields (`BDR-016`) — never shown again in
/// the generic "Additional Information" custom-field list below.
const _standardFieldKeys = {'name', 'capacity', 'description', 'location'};

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
          if (_status == _LoadStatus.ready)
            IconButton(onPressed: _openEdit, icon: const Icon(Icons.edit_outlined), tooltip: 'Edit'),
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
        return HHEmptyState(
          icon: Icons.error_outline,
          message: _errorMessage ?? 'Something went wrong.',
          iconColor: HHColors.danger700,
          actionLabel: 'Retry',
          onAction: _load,
        );

      case _LoadStatus.ready:
        final hall = _hall!;
        final profileData = hall.profileData;
        if (profileData == null || profileData.isEmpty) {
          return const Center(child: Text('No profile information yet.'));
        }

        final customFields = profileData.entries
            .where((entry) => !_standardFieldKeys.contains(entry.key))
            .toList();

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(HHSpacing.space7),
            children: [
              if (hall.photos.isNotEmpty) ...[
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: hall.photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: HHSpacing.space3),
                    itemBuilder: (context, index) => HHNetworkImage(
                      url: hall.photos[index].url,
                      width: 220,
                      height: 160,
                    ),
                  ),
                ),
                const SizedBox(height: HHSpacing.space7),
              ],
              HHCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      icon: Icons.groups_2_outlined,
                      label: 'Capacity',
                      value: hall.capacity?.toString() ?? 'Not set',
                    ),
                    if (hall.location != null) ...[
                      const SizedBox(height: HHSpacing.space4),
                      _DetailRow(
                        icon: Icons.place_outlined,
                        label: 'Location / Area',
                        value: hall.location!,
                      ),
                    ],
                    if (hall.description != null) ...[
                      const SizedBox(height: HHSpacing.space5),
                      Text(
                        'Description',
                        style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textXs),
                      ),
                      const SizedBox(height: HHSpacing.space2),
                      Text(hall.description!, style: TextStyle(fontSize: HHTypeScale.textMd, height: 1.4)),
                    ],
                  ],
                ),
              ),
              if (customFields.isNotEmpty) ...[
                const SizedBox(height: HHSpacing.space7),
                const HHSectionLabel('ADDITIONAL INFORMATION'),
                HHCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in customFields)
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
              ],
              const SizedBox(height: HHSpacing.space7),
              const HHSectionLabel('DETAILS'),
              HHCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Created ${hall.createdAt.toLocal()}', style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textSm)),
                    const SizedBox(height: HHSpacing.space2),
                    Text('Last updated ${hall.updatedAt.toLocal()}', style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textSm)),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: HHColors.actionPrimary),
        const SizedBox(width: HHSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: HHColors.textMuted, fontSize: HHTypeScale.textXs)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: HHTypeScale.textMd)),
            ],
          ),
        ),
      ],
    );
  }
}
