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
    this.customerFullName,
    this.customerMobileNumber,
    this.customerAvatarUrl,
    this.hallName,
    this.cancellationReason,
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
  // BDR-018 — null only for a Customer who registered before Full Name was
  // required and has not since set one; never a fake/placeholder value.
  final String? customerFullName;
  final String? customerMobileNumber;
  // Null until the Customer uploads an avatar — never a fake/placeholder value.
  final String? customerAvatarUrl;
  // Null only if the Hall has no `profileData.name` set yet — never a
  // fake/placeholder value.
  final String? hallName;
  // BDR-024 — set only when the Customer cancelled a Confirmed booking;
  // null for a Pending cancellation (never required) or a Manager's own.
  final String? cancellationReason;

  factory ManagerBooking.fromJson(Map<String, dynamic> json) {
    final pricing = (json['pricing'] as Map).cast<String, dynamic>();
    final payment = (json['payment'] as Map).cast<String, dynamic>();
    final customer = (json['customer'] as Map?)?.cast<String, dynamic>();
    final hall = (json['hall'] as Map?)?.cast<String, dynamic>();
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
      customerFullName: customer?['fullName'] as String?,
      customerMobileNumber: customer?['mobileNumber'] as String?,
      customerAvatarUrl: customer?['avatarUrl'] as String?,
      hallName: hall?['name'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }
}

/// Manager Dashboard Overview — `GET /hotels/:hotelId/bookings/summary`.
class BookingSummary {
  const BookingSummary({
    required this.totalBookings,
    required this.totalRevenueCents,
    required this.pendingCount,
  });

  final int totalBookings;
  final int totalRevenueCents;
  final int pendingCount;

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      totalBookings: json['totalBookings'] as int,
      totalRevenueCents: json['totalRevenueCents'] as int,
      pendingCount: json['pendingCount'] as int,
    );
  }
}
