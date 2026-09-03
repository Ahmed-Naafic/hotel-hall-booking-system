import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'booking_models.dart';

class ManagerBookingRepository {
  ManagerBookingRepository(this._client);
  final ApiClient _client;

  Future<List<ManagerBooking>> list(String hotelId) async {
    final result = await _client.getPaginated(
      '/hotels/$hotelId/bookings',
      query: {'limit': '100'},
    );
    return (result.data as List)
        .map(
          (item) =>
              ManagerBooking.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<void> action(
    String hotelId,
    String bookingId,
    String action, {
    Object? body,
  }) =>
      _client.post('/hotels/$hotelId/bookings/$bookingId/$action', body: body);
}
