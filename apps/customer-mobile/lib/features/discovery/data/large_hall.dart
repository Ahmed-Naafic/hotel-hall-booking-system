import 'discovery_models.dart';

/// A Hall returned by `GET /halls/large-capacity` — the same Hall shape as
/// [HallSummary] plus the owning Hotel's name (needed here because, unlike
/// a Hotel's own "Available halls" list, this Hall is shown outside the
/// context of any already-known Hotel screen).
class LargeHall {
  const LargeHall({required this.hall, required this.hotelName});

  final HallSummary hall;
  final String? hotelName;

  String get id => hall.id;
  String get name => hall.name;
  String get capacity => hall.capacity;

  factory LargeHall.fromJson(Map<String, dynamic> json) => LargeHall(
    hall: HallSummary.fromJson(json),
    hotelName: (json['hotel'] as Map?)?['name'] as String?,
  );
}
