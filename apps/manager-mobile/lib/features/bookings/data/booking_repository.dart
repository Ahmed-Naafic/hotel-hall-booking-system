import 'dart:async';

import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../../../core/sync/local_replica.dart';
import '../../../core/sync/offline_fallback.dart';
import 'booking_models.dart';

/// Reads are server first, with the replica as the offline fallback
/// ([serverFirst]); actions are server only. [replica] is optional — without
/// one, offline is an error, as it always was.
class ManagerBookingRepository {
  ManagerBookingRepository(this._client, {this.replica});
  final ApiClient _client;
  final LocalReplica? replica;

  /// Newest first, as `GET /hotels/:hotelId/bookings` orders them.
  ///
  /// Offline, the replica's Bookings carry no customer name or number — they
  /// are never replicated (business decision #3) — so those fields are null and
  /// the screen shows what it shows for any Booking without them.
  Future<List<ManagerBooking>> list(String hotelId, {int limit = 100}) => serverFirst(
    replica,
    online: () async {
      final result = await _client.getPaginated(
        '/hotels/$hotelId/bookings',
        query: {'limit': '$limit'},
      );
      return (result.data as List)
          .map((item) => ManagerBooking.fromJson((item as Map).cast<String, dynamic>()))
          .toList();
    },
    local: (replica) => localBookings(replica, hotelId, limit: limit),
  );

  /// Every lifecycle action responds with the Booking as it now stands, so
  /// the caller can show the result without waiting on a list refetch.
  ///
  /// Never falls back: confirming, rejecting or verifying a payment is decided
  /// by the server against current state (Technical Design §12). Offline it
  /// fails with a [NetworkException], and the replica catches up by syncing.
  Future<ManagerBooking> action(
    String hotelId,
    String bookingId,
    String action, {
    Object? body,
  }) async {
    final data = await _client.post(
      '/hotels/$hotelId/bookings/$bookingId/$action',
      body: body,
    );
    unawaited(replica?.sync());
    return ManagerBooking.fromJson((data as Map).cast<String, dynamic>());
  }

  /// Offline, the last summary the server returned — not a recomputation.
  /// What counts as revenue is the server's rule
  /// (`booking.repository.js#getSummary`); computing it here would copy that
  /// rule into a second place that could drift from the first.
  Future<BookingSummary> summary(String hotelId) => serverFirst(
    replica,
    online: () async {
      final data = (await _client.get('/hotels/$hotelId/bookings/summary') as Map).cast<String, dynamic>();
      await replica?.cachePut(_summaryKey(hotelId), data);
      return BookingSummary.fromJson(data);
    },
    local: (replica) async {
      final cached = await replica.cacheGet(_summaryKey(hotelId));
      return cached == null ? null : BookingSummary.fromJson((cached as Map).cast<String, dynamic>());
    },
  );

  static String _summaryKey(String hotelId) => 'bookingSummary:$hotelId';
}

/// One Hotel's replicated Bookings, newest first, each joined to its Hall's
/// name from the replicated Halls — the REST list embeds that name, the sync
/// row does not. Null when the replica cannot answer.
Future<List<ManagerBooking>?> localBookings(LocalReplica replica, String hotelId, {int? limit}) async {
  final bookings = await replica.readable('booking');
  if (bookings == null) return null;
  final rows = await bookings.select(
    'booking',
    where: 'hotel_id = ?',
    args: [hotelId],
    orderBy: "json_extract(data, '\$.createdAt') DESC, id DESC",
    limit: limit,
  );

  final halls = await replica.readable('hall');
  final hallNames = <String, String?>{
    if (halls != null)
      for (final hall in await halls.forHotel('hall', hotelId))
        hall['id'] as String: (hall['profileData'] as Map?)?['name'] as String?,
  };

  return [
    for (final row in rows)
      ManagerBooking.fromJson({
        ...row,
        if (hallNames.containsKey(row['hallId'])) 'hall': {'name': hallNames[row['hallId']]},
      }),
  ];
}
