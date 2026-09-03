/// Mirrors the Manager-facing shape `toManagerAvailabilityBlock` returns —
/// every field the backend actually sends, nothing invented, nothing
/// omitted (matches `Hall`/`HallMedia`'s own factory style).
class AvailabilityBlock {
  const AvailabilityBlock({
    required this.id,
    required this.hallId,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String hallId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? reason;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AvailabilityBlock.fromJson(Map<String, dynamic> json) => AvailabilityBlock(
    id: json['id'] as String,
    hallId: json['hallId'] as String,
    startsAt: DateTime.parse(json['startsAt'] as String),
    endsAt: DateTime.parse(json['endsAt'] as String),
    reason: json['reason'] as String?,
    createdByUserId: json['createdByUserId'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
