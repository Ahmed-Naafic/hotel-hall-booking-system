/// A single busy [start, end) period for one Hall on one day — the only
/// shape the public Customer availability endpoint ever returns. No
/// reason, no id, no indication of whether it's a booking or a manual
/// block, and never another Customer's personal information (Approved
/// Technical Design §9).
class BusyPeriod {
  const BusyPeriod({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  factory BusyPeriod.fromJson(Map<String, dynamic> json) => BusyPeriod(
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
  );
}
