class Booking {
  const Booking({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.totalRentCents,
    required this.requiredAdvanceCents,
  });
  final String id;
  final String status;
  final String paymentStatus;
  final int totalRentCents;
  final int requiredAdvanceCents;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final pricing = (json['pricing'] as Map).cast<String, dynamic>();
    return Booking(
      id: json['id'] as String,
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      totalRentCents: pricing['totalRentCents'] as int,
      requiredAdvanceCents: pricing['requiredAdvanceCents'] as int,
    );
  }
}
