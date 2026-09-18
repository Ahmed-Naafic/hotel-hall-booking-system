import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/manager_formatters.dart';
import '../../data/hotel_models.dart';
import '../../data/hotel_repository.dart';
import '../widgets/hotel_onboarding.dart';
import 'hotel_photo_viewer_screen.dart';
import 'hotel_profile_form_screen.dart';

enum _LoadStatus { loading, ready, error }

/// Manager → My Hotel → Hotel Details — a read-only view of the Hotel's
/// full profile (`GET /hotels/:id` + `GET /hotels/:id/media`), including its
/// Logo and Photos. Tapping the [HotelIdentityCard] on [MyHotelScreen]
/// always lands here first, never straight into the edit form — editing is
/// its own explicit action (the AppBar's Edit icon), matching the same
/// view-first pattern already used by `HallDetailsScreen`.
///
/// Independently fetches its own copy of the Hotel and its Media by id,
/// exactly like `HallDetailsScreen` does for a Hall — so it always reflects
/// the latest saved state, never a possibly-stale copy the caller already
/// had.
class HotelDetailsScreen extends StatefulWidget {
  const HotelDetailsScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  _LoadStatus _status = _LoadStatus.loading;
  Hotel? _hotel;
  HotelMediaCollection? _media;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _LoadStatus.loading);
    try {
      final repository = HotelRepository(context.read<ApiClient>());
      final results = await Future.wait([
        repository.getHotel(widget.hotelId),
        repository.getMedia(widget.hotelId),
      ]);
      if (!mounted) return;
      setState(() {
        _hotel = results[0] as Hotel;
        _media = results[1] as HotelMediaCollection;
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

  /// Only `APPROVED_ACTIVE`/`REJECTED` Hotels can actually be edited — the
  /// backend rejects `PATCH /hotels/:id` with `422` for every other status
  /// (`hotel.controller.js#updateHotel`), so the Edit action never appears
  /// for a status it would only fail against.
  Future<void> _openEdit() async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const HotelProfileFormScreen()),
    );
    if (done == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hotel profile updated.')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotel = _hotel;
    final isEditable = hotel != null && (hotel.status == 'APPROVED_ACTIVE' || hotel.status == 'REJECTED');
    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(
        title: Text(hotel?.profileData?['name']?.toString().trim().isNotEmpty == true
            ? hotel!.profileData!['name'].toString()
            : 'Hotel Details'),
        actions: [
          if (isEditable)
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
          iconColor: context.hh.danger700,
          actionLabel: 'Retry',
          onAction: _load,
        );

      case _LoadStatus.ready:
        final hotel = _hotel!;
        final media = _media!;
        final logo = media.logo;
        final photos = media.photos;
        final profileData = hotel.profileData;
        final description = profileData?['description']?.toString().trim();
        final location = profileData?['location'];
        final locationAddress = location is Map
            ? location['address']?.toString().trim()
            : (location is String ? location.trim() : null);
        final contactPhone = profileData?['contactPhone']?.toString().trim();
        final email = profileData?['email']?.toString().trim();
        final customFields = (profileData ?? const <String, dynamic>{}).entries
            .where((entry) => !_standardFieldKeys.contains(entry.key))
            .toList();

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(HHSpacing.space7),
            children: [
              HHStatusBadge(
                label: ManagerFormatters.status(hotel.status),
                tone: toneForHotelStatus(hotel.status),
              ),
              const SizedBox(height: HHSpacing.space6),
              if (logo != null) ...[
                Text(
                  'Hotel Logo',
                  style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textXs),
                ),
                const SizedBox(height: HHSpacing.space3),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HotelPhotoViewerScreen(photos: [logo], initialIndex: 0),
                    ),
                  ),
                  child: HHNetworkImage(url: logo.url, width: 96, height: 96),
                ),
                const SizedBox(height: HHSpacing.space7),
              ],
              if (photos.isNotEmpty) ...[
                Text(
                  'Hotel Photos',
                  style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textXs),
                ),
                const SizedBox(height: HHSpacing.space3),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (context, index) => const SizedBox(width: HHSpacing.space3),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HotelPhotoViewerScreen(photos: photos, initialIndex: index),
                        ),
                      ),
                      child: HHNetworkImage(
                        url: photos[index].url,
                        width: 220,
                        height: 160,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: HHSpacing.space7),
              ],
              if (description == null &&
                  locationAddress == null &&
                  contactPhone == null &&
                  email == null)
                const Center(child: Text('No profile information yet.'))
              else
                HHCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (locationAddress != null && locationAddress.isNotEmpty) ...[
                        _DetailRow(icon: Icons.place_outlined, label: 'Location', value: locationAddress),
                        const SizedBox(height: HHSpacing.space4),
                      ],
                      if (contactPhone != null && contactPhone.isNotEmpty) ...[
                        _DetailRow(icon: Icons.phone_outlined, label: 'Contact Phone', value: contactPhone),
                        const SizedBox(height: HHSpacing.space4),
                      ],
                      if (email != null && email.isNotEmpty) ...[
                        _DetailRow(icon: Icons.email_outlined, label: 'Email', value: email),
                        const SizedBox(height: HHSpacing.space4),
                      ],
                      if (description != null && description.isNotEmpty) ...[
                        Text(
                          'Description',
                          style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textXs),
                        ),
                        const SizedBox(height: HHSpacing.space2),
                        Text(description, style: TextStyle(fontSize: HHTypeScale.textMd, height: 1.4)),
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
                              Text(
                                ManagerFormatters.label(entry.key),
                                style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textXs),
                              ),
                              Text(entry.value?.toString() ?? '', style: TextStyle(fontSize: HHTypeScale.textMd)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
    }
  }
}

/// The Hotel's own named standard fields (`BDR-015`) — never shown again in
/// the generic "Additional Information" custom-field list above.
const _standardFieldKeys = {'name', 'description', 'location', 'contactPhone', 'email'};

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
        Icon(icon, size: 18, color: context.hh.actionPrimary),
        const SizedBox(width: HHSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textXs)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: HHTypeScale.textMd)),
            ],
          ),
        ),
      ],
    );
  }
}
