import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../../../core/presentation/manager_formatters.dart';
import '../../../../core/presentation/stat_tile.dart';
import '../../../bookings/data/booking_models.dart';
import '../../data/hotel_models.dart';
import 'hotel_onboarding.dart';

/// [MyHotelScreen]'s own richer profile presentation — hero photo, name,
/// a Verified badge, location, real rating, an at-a-glance stat grid
/// (Status / Member Since / Total Halls / Total Bookings), an About
/// excerpt, and an Edit Profile action. Every value shown is either the
/// `Hotel`/`HotelMediaCollection` this screen already fetched, a real
/// database-side aggregate (`HallRepository.listHalls().total`,
/// `ManagerBookingRepository.summary()`, `GET /hotels/me`'s
/// `reviewSummary`), or directly derived from the Hotel's own real
/// `status` (the Verified badge — shown only when `APPROVED_ACTIVE`, never
/// a separate invented flag) — the same "never invent a stat" discipline
/// `DashboardScreen`'s Overview grid already follows.
class HotelProfileHeader extends StatelessWidget {
  const HotelProfileHeader({
    super.key,
    required this.hotel,
    required this.media,
    required this.reviewSummary,
    required this.hallCountFuture,
    required this.summaryFuture,
    this.onOpenPhotos,
    this.onOpenHallsTab,
    this.onOpenBookingsTab,
    this.onEdit,
  });

  final Hotel hotel;
  final HotelMediaCollection? media;
  final ReviewSummary? reviewSummary;
  final Future<int>? hallCountFuture;
  final Future<BookingSummary>? summaryFuture;

  /// Tapping the hero photo — opens the full read-only profile
  /// (`HotelDetailsScreen`'s photo gallery, location, contact info,
  /// custom fields), never duplicated here.
  final VoidCallback? onOpenPhotos;
  final VoidCallback? onOpenHallsTab;
  final VoidCallback? onOpenBookingsTab;

  /// The bottom "Edit Profile" button — `null` (never rendered) when the
  /// Hotel's current status doesn't permit editing, the same guard
  /// `HotelDetailsScreen`'s own Edit action already applies.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final profileData = hotel.profileData;
    final name = profileData?['name']?.toString().trim();
    final location = profileData?['location'];
    final locationAddress = location is Map
        ? location['address']?.toString().trim()
        : (location is String ? location.trim() : null);
    final description = profileData?['description']?.toString().trim();
    final photos = media?.photos ?? const <HotelMedia>[];
    final heroUrl = media?.logo?.url ?? (photos.isEmpty ? null : photos.first.url);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onOpenPhotos,
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 180,
                child: HHNetworkImage(
                  url: heroUrl,
                  width: double.infinity,
                  height: 180,
                  fallbackIcon: Icons.apartment_outlined,
                ),
              ),
              if (photos.isNotEmpty)
                Positioned(
                  right: HHSpacing.space3,
                  bottom: HHSpacing.space3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: HHSpacing.space3, vertical: HHSpacing.space1),
                    decoration: BoxDecoration(
                      color: context.hh.surfaceGlassDark,
                      borderRadius: BorderRadius.circular(HHRadii.pill),
                    ),
                    child: Text(
                      '${photos.length} Photo${photos.length == 1 ? '' : 's'}',
                      style: TextStyle(color: context.hh.textInverse, fontSize: HHTypeScale.textXs, fontWeight: HHTypeScale.weightSemibold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: HHSpacing.space5),
        GestureDetector(
          onTap: onOpenPhotos,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      (name == null || name.isEmpty) ? 'My Hotel' : name,
                      style: TextStyle(fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.text2xl),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // "Verified" is this Hotel's own real `APPROVED_ACTIVE`
                  // status shown as a badge, not a second invented flag —
                  // an approved Hotel genuinely was reviewed and approved
                  // by a Platform Administrator (`BDR-003`).
                  if (hotel.status == 'APPROVED_ACTIVE') ...[
                    const SizedBox(width: HHSpacing.space2),
                    Icon(Icons.verified, size: 18, color: context.hh.info700),
                    const SizedBox(width: 2),
                    Text(
                      'Verified',
                      style: TextStyle(color: context.hh.info700, fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.textSm),
                    ),
                  ],
                ],
              ),
              if (locationAddress != null && locationAddress.isNotEmpty) ...[
                const SizedBox(height: HHSpacing.space2),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 16, color: context.hh.textMuted),
                    const SizedBox(width: HHSpacing.space2),
                    Expanded(
                      child: Text(
                        locationAddress,
                        style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textSm),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              // The real review aggregate (`GET /hotels/me`'s
              // `reviewSummary`) — omitted entirely while the Hotel has
              // zero reviews, never a fabricated "0.0" or placeholder.
              if (reviewSummary != null && reviewSummary!.count > 0) ...[
                const SizedBox(height: HHSpacing.space2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: HHColors.gold600),
                    const SizedBox(width: HHSpacing.space1),
                    Text(
                      '${reviewSummary!.average} (${reviewSummary!.count} review${reviewSummary!.count == 1 ? '' : 's'})',
                      style: TextStyle(fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.textSm),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: HHSpacing.space5),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // A fixed height (rather than `childAspectRatio`) so the tile's
          // actual content — icon chip, value, label, card padding —
          // always fits regardless of the grid's width; an aspect ratio
          // derives height from width alone and overflows at ordinary
          // phone widths, the same fix `DashboardScreen`'s own Overview
          // grid already applies, matched here for the identical content
          // shape (and this screen's own "Hotel Status" value can run
          // longer than Dashboard's always-short numeric/currency ones,
          // e.g. "Restricted Under Review").
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: HHSpacing.space4,
            crossAxisSpacing: HHSpacing.space4,
            mainAxisExtent: 140,
          ),
          children: [
            StatTile(
              icon: statusIcon(toneForHotelStatus(hotel.status)),
              iconColor: toneColor(context, toneForHotelStatus(hotel.status)),
              iconBg: toneColor(context, toneForHotelStatus(hotel.status)).withValues(alpha: 0.12),
              label: 'Hotel Status',
              value: ManagerFormatters.status(hotel.status),
              onTap: onOpenPhotos,
            ),
            StatTile(
              icon: Icons.calendar_today_outlined,
              iconColor: context.hh.actionPrimary,
              iconBg: context.hh.surfaceNavyTint,
              label: 'Member Since',
              value: ManagerFormatters.date(hotel.createdAt),
            ),
            FutureBuilder<int>(
              future: hallCountFuture,
              builder: (context, snapshot) => StatTile(
                icon: Icons.meeting_room_outlined,
                iconColor: context.hh.actionAccent,
                iconBg: context.hh.surfaceTealTint,
                label: 'Total Halls',
                value: statTileValueOf(snapshot, snapshot.data?.toString()),
                onTap: onOpenHallsTab,
              ),
            ),
            FutureBuilder<BookingSummary>(
              future: summaryFuture,
              builder: (context, snapshot) => StatTile(
                icon: Icons.event_note_outlined,
                iconColor: context.hh.actionGold,
                iconBg: context.hh.surfaceGoldTint,
                label: 'Total Bookings',
                value: statTileValueOf(snapshot, snapshot.data?.totalBookings.toString()),
                onTap: onOpenBookingsTab,
              ),
            ),
          ],
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: HHSpacing.space6),
          HHCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HHSectionLabel('ABOUT HOTEL'),
                Text(description, style: TextStyle(fontSize: HHTypeScale.textMd, height: 1.45)),
              ],
            ),
          ),
        ],
        if (onEdit != null) ...[
          const SizedBox(height: HHSpacing.space6),
          HHPrimaryButton(label: 'Edit Profile', onPressed: onEdit),
        ],
      ],
    );
  }

  /// A tone-appropriate icon for the Hotel Status tile — never a checkmark
  /// for a non-`success` tone, which would visually read as "good" even
  /// when colored red/amber.
  static IconData statusIcon(HHBadgeTone tone) {
    switch (tone) {
      case HHBadgeTone.success:
        return Icons.verified_outlined;
      case HHBadgeTone.warning:
        return Icons.hourglass_top_outlined;
      case HHBadgeTone.danger:
        return Icons.block_outlined;
      case HHBadgeTone.info:
      case HHBadgeTone.neutral:
        return Icons.info_outline;
    }
  }

  static Color toneColor(BuildContext context, HHBadgeTone tone) {
    switch (tone) {
      case HHBadgeTone.success:
        return context.hh.success700;
      case HHBadgeTone.warning:
        return context.hh.warning700;
      case HHBadgeTone.danger:
        return context.hh.danger700;
      case HHBadgeTone.info:
        return context.hh.info700;
      case HHBadgeTone.neutral:
        return context.hh.textMuted;
    }
  }
}
