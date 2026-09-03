class ManagerBooking {
  const ManagerBooking({
    required this.id,
    required this.hallId,
    required this.startsAt,
    required this.endsAt,
    required this.guests,
    required this.eventType,
    required this.status,
    required this.paymentStatus,
    required this.totalRentCents,
    required this.requiredAdvanceCents,
    this.reportedAmountCents,
  });
  final String id;
  final String hallId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int guests;
  final String eventType;
  final String status;
  final String paymentStatus;
  final int totalRentCents;
  final int requiredAdvanceCents;
  final int? reportedAmountCents;

  factory ManagerBooking.fromJson(Map<String, dynamic> json) {
    final pricing = (json['pricing'] as Map).cast<String, dynamic>();
    final payment = (json['payment'] as Map).cast<String, dynamic>();
    return ManagerBooking(
      id: json['id'] as String,
      hallId: json['hallId'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      guests: json['numberOfGuests'] as int,
      eventType: json['eventType'] as String,
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      totalRentCents: pricing['totalRentCents'] as int,
      requiredAdvanceCents: pricing['requiredAdvanceCents'] as int,
      reportedAmountCents: payment['reportedAmountCents'] as int?,
    );
  }
}
