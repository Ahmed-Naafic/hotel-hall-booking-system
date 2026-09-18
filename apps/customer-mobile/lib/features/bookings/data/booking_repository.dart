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

  /// The Customer's own booking history (`GET /bookings`), newest first.
  Future<List<Booking>> list({String? cursor, int limit = 20}) async {
    final result = await _client.getPaginated(
      '/bookings',
      query: {'limit': '$limit', if (cursor != null) 'cursor': cursor},
    );
    return (result.data as List)
        .map((item) => Booking.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Booking> get(String bookingId) async {
    final data = await _client.get('/bookings/$bookingId');
    return Booking.fromJson((data as Map).cast<String, dynamic>());
  }

  /// Cancels the Customer's own applicable Booking. The record is never
  /// deleted — the backend transitions it to CANCELLED and preserves it in
  /// history. `reason` is required by the backend only when the Booking
  /// being cancelled is CONFIRMED (BDR-024); omitted (never sent as an
  /// empty string) when cancelling a still-PENDING one.
  Future<Booking> cancel(String bookingId, {String? reason}) async {
    final trimmed = reason?.trim();
    final data = await _client.post(
      '/bookings/$bookingId/cancellation',
      body: trimmed?.isNotEmpty == true ? {'reason': trimmed} : null,
    );
    return Booking.fromJson((data as Map).cast<String, dynamic>());
  }

  /// Ratings & Reviews V1 — the backend is the sole authority for
  /// eligibility (a COMPLETED Booking, not already reviewed); this only
  /// forwards the Customer's rating/text and parses the updated Booking.
  Future<Booking> submitReview({
    required String bookingId,
    required int rating,
    String? text,
  }) async {
    final data = await _client.post(
      '/bookings/$bookingId/review',
      body: {
        'rating': rating,
        if (text?.trim().isNotEmpty == true) 'text': text!.trim(),
      },
    );
    return Booking.fromJson((data as Map).cast<String, dynamic>());
  }
}
