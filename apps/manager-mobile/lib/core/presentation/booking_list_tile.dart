import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../features/bookings/data/booking_models.dart';
import 'manager_formatters.dart';

/// A compact Booking row — initials avatar, customer name, Hall + date/time,
/// and a colored status pill. Shared by the Dashboard's Recent Bookings and
/// the Bookings tab's own list so both render a Booking identically rather
/// than two copies that could drift.
class BookingListTile extends StatelessWidget {
  const BookingListTile({super.key, required this.booking, this.onTap});

  final ManagerBooking booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = booking.customerFullName ?? booking.customerMobileNumber ?? 'Customer';
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final avatarUrl = booking.customerAvatarUrl;

    Widget initialsAvatar() => CircleAvatar(
      radius: 20,
      backgroundColor: context.hh.surfaceNavyTint,
      child: Text(initial, style: TextStyle(color: context.hh.textHeading, fontWeight: HHTypeScale.weightSemibold)),
    );

    return HHCard(
      onTap: onTap,
      padding: const EdgeInsets.all(HHSpacing.space4),
      child: Row(
        children: [
          avatarUrl == null || avatarUrl.isEmpty
              ? initialsAvatar()
              : ClipOval(
                  child: Image.network(
                    avatarUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => initialsAvatar(),
                  ),
                ),
          const SizedBox(width: HHSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: HHTypeScale.weightSemibold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.hallName ?? 'Hall'} • ${ManagerFormatters.date(booking.startsAt)} • '
                  '${ManagerFormatters.time(booking.startsAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textXs),
                ),
              ],
            ),
          ),
          const SizedBox(width: HHSpacing.space3),
          HHStatusBadge(label: ManagerFormatters.status(booking.status), tone: toneForBookingStatus(booking.status)),
        ],
      ),
    );
  }
}
