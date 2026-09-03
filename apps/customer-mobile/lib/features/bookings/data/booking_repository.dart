import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'booking_models.dart';

class BookingRepository {
  BookingRepository(this._client);
  final ApiClient _client;

  Future<Booking> create({
    required String hallId,
    required DateTime startsAt,
    required DateTime endsAt,
    required int numberOfGuests,
    required String eventType,
    String? specialRequest,
  }) async {
    final data = await _client.post(
      '/bookings',
      body: {
        'hallId': hallId,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
        'numberOfGuests': numberOfGuests,
        'eventType': eventType,
        if (specialRequest?.trim().isNotEmpty == true)
          'specialRequest': specialRequest!.trim(),
      },
    );
    return Booking.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<Booking> reportPayment({
    required String bookingId,
    required int amountCents,
  }) async {
    final data = await _client.post(
      '/bookings/$bookingId/payment-report',
      body: {'amountCents': amountCents},
    );
    return Booking.fromJson((data as Map).cast<String, dynamic>());
  }
}
