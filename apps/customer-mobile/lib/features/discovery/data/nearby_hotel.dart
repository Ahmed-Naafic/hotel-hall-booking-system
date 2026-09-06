import 'discovery_models.dart';

/// A Hotel returned by `GET /hotels/public/nearby` — the same
/// Customer-visible Hotel shape as [HotelSummary] plus the backend-computed
/// `distanceKm` (approved business rules: Customer Mobile never
/// independently calculates or filters proximity).
class NearbyHotel {
  const NearbyHotel({required this.hotel, required this.distanceKm});

  final HotelSummary hotel;
  final double distanceKm;

  String get id => hotel.id;
  String get name => hotel.name;
  String get location => hotel.location;

  factory NearbyHotel.fromJson(Map<String, dynamic> json) => NearbyHotel(
    hotel: HotelSummary.fromJson(json),
    distanceKm: (json['distanceKm'] as num).toDouble(),
  );
}
