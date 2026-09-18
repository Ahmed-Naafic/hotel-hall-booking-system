import 'package:hotel_hall_core/hotel_hall_core.dart';

/// Purely presentational — maps the backend's own Booking status string to
/// a visual tone, never a business judgment. Every branch renders the
/// backend's exact status text (via `ManagerFormatters.status`); only the
/// color changes. Shared by the Dashboard's Recent Bookings and the
/// Calendar tab's day list so both render the identical status→tone
/// mapping rather than two copies that could drift.
HHBadgeTone toneForBookingStatus(String status) {
  switch (status) {
    case 'CONFIRMED':
    case 'COMPLETED':
      return HHBadgeTone.success;
    case 'PENDING':
      return HHBadgeTone.warning;
    case 'REJECTED':
    case 'CANCELLED':
    case 'NO_SHOW':
    case 'EXPIRED':
      return HHBadgeTone.danger;
    default:
      return HHBadgeTone.neutral;
  }
}

/// Pure, presentation-only text formatting — never a source of truth.
/// `status()` and `label()` only reformat casing/spacing of a value the
/// backend/manager already supplied verbatim (e.g. `APPROVED_ACTIVE` ->
/// `Approved Active`, `amenities` -> `Amenities`); neither invents,
/// re-derives, or judges the underlying value.
abstract final class ManagerFormatters {
  static String status(String value) => value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');

  static String date(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = value.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String time(DateTime value) {
    final local = value.toLocal();
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  static String label(String key) {
    final spaced = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();
    return spaced.isEmpty
        ? key
        : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  static String? text(Map<String, dynamic>? data, String key) {
    final value = data?[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// Whole-dollar, thousands-grouped display of a cents amount (`2458000`
  /// -> `$24,580`) — Dashboard Overview only ever shows whole currency
  /// units, never fractional cents.
  static String moneyCents(int cents) {
    final dollars = (cents / 100).round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < dollars.length; i++) {
      if (i > 0 && (dollars.length - i) % 3 == 0) buffer.write(',');
      buffer.write(dollars[i]);
    }
    return '\$$buffer';
  }
}
