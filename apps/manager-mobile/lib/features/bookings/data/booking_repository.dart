import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'booking_models.dart';

class ManagerBookingRepository {
  ManagerBookingRepository(this._client);
  final ApiClient _client;

  Future<List<ManagerBooking>> list(String hotelId, {int limit = 100}) async {
    final result = await _client.getPaginated(
      '/hotels/$hotelId/bookings',
      query: {'limit': '$limit'},
    );
    return (result.data as List)
        .map(
          (item) =>
              ManagerBooking.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  /// Every lifecycle action responds with the Booking as it now stands, so
  /// the caller can show the result without waiting on a list refetch.
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
    return ManagerBooking.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<BookingSummary> summary(String hotelId) async {
    final data = await _client.get('/hotels/$hotelId/bookings/summary');
    return BookingSummary.fromJson((data as Map).cast<String, dynamic>());
  }
}
