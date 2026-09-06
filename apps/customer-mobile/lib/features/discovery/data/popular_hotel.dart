import 'discovery_models.dart';

/// A Hotel returned by `GET /hotels/public/popular` — the same
/// Customer-visible Hotel shape as [HotelSummary] plus the backend-computed
/// `bookingCount` (approved business rules: a real qualifying booking
/// count only — never a score, rating, or other invented ranking value).
class PopularHotel {
  const PopularHotel({required this.hotel, required this.bookingCount});

  final HotelSummary hotel;
  final int bookingCount;

  String get id => hotel.id;
  String get name => hotel.name;
  String get location => hotel.location;

  factory PopularHotel.fromJson(Map<String, dynamic> json) => PopularHotel(
    hotel: HotelSummary.fromJson(json),
    bookingCount: (json['bookingCount'] as num).toInt(),
  );
}
