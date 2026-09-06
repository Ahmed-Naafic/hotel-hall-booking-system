import 'discovery_models.dart';

/// A Hall returned by the platform-wide `GET /halls` browse (All Halls) —
/// the same Hall shape as [HallSummary] plus the owning Hotel's name, shown
/// outside the context of any already-known Hotel screen. Deliberately a
/// separate small type from Large Halls' own model — same shape, different
/// feature, so neither risks the other when one changes.
class BrowsableHall {
  const BrowsableHall({required this.hall, required this.hotelName});

  final HallSummary hall;
  final String? hotelName;

  String get id => hall.id;
  String get name => hall.name;
  String get capacity => hall.capacity;

  factory BrowsableHall.fromJson(Map<String, dynamic> json) => BrowsableHall(
    hall: HallSummary.fromJson(json),
    hotelName: (json['hotel'] as Map?)?['name'] as String?,
  );
}
