/// The Hotel identity attached to a Booking (name only — Hotel Management
/// owns everything else about it). Present whenever the backend embeds it
/// (every current Booking response), optional here only so a future gap in
/// that embedding never crashes parsing.
class BookingHotel {
  const BookingHotel({required this.id, this.name});
  final String id;
  final String? name;

  factory BookingHotel.fromJson(Map<String, dynamic> json) =>
      BookingHotel(id: json['id'] as String, name: json['name'] as String?);
}

/// The Hall identity and commercial/payment terms attached to a Booking —
/// the same `bookingTerms` shape `HallSummary` already parses (Hall
/// Management's `toPublicHall`), so a Customer sees identical figures
/// whether browsing the Hall or reviewing an existing Booking.
class BookingHall {
  const BookingHall({required this.id, this.name, this.bookingTerms = const {}});
  final String id;
  final String? name;
  final Map<String, dynamic> bookingTerms;

  int? get rentAmountCents => bookingTerms['rentAmountCents'] as int?;
  int get rentDurationHours => bookingTerms['rentDurationHours'] as int? ?? 24;
  double? get advancePaymentPercent =>
      (bookingTerms['advancePaymentPercent'] as num?)?.toDouble();
  String get paymentReceivingNumber =>
      bookingTerms['paymentReceivingNumber'] as String? ?? '';
  String get customerServiceNumber =>
      bookingTerms['customerServiceNumber'] as String? ?? '';

  factory BookingHall.fromJson(Map<String, dynamic> json) => BookingHall(
    id: json['id'] as String,
    name: json['name'] as String?,
    bookingTerms:
        (json['bookingTerms'] as Map?)?.cast<String, dynamic>() ?? const {},
  );
}

/// A Customer's review of the completed Booking it belongs to (Ratings &
/// Reviews V1, approved business decisions) — never carries any Customer
/// identity, since none is exposed publicly anywhere in this platform.
class BookingReview {
  const BookingReview({
    required this.id,
    required this.rating,
    this.text,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String? text;
  final DateTime createdAt;

  factory BookingReview.fromJson(Map<String, dynamic> json) => BookingReview(
    id: json['id'] as String,
    rating: json['rating'] as int,
    text: json['text'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class Booking {
  const Booking({
    required this.id,
    required this.hotelId,
    required this.hallId,
    this.hotel,
    this.hall,
    required this.startsAt,
    required this.endsAt,
    required this.numberOfGuests,
    required this.eventType,
    this.specialRequest,
    required this.status,
    required this.paymentStatus,
    this.paymentDeadlineAt,
    required this.totalRentCents,
    required this.advancePercent,
    required this.requiredAdvanceCents,
    this.reportedAmountCents,
    this.paymentReportedAt,
    this.paymentVerifiedAt,
    this.paymentRejectionReason,
    required this.createdAt,
    this.review,
  });

  final String id;
  final String hotelId;
  final String hallId;
  final BookingHotel? hotel;
  final BookingHall? hall;
  final DateTime startsAt;
  final DateTime endsAt;
  final int numberOfGuests;
  final String eventType;
  final String? specialRequest;
  final String status;
  final String paymentStatus;
  final DateTime? paymentDeadlineAt;
  final int totalRentCents;
  final double advancePercent;
  final int requiredAdvanceCents;
  final int? reportedAmountCents;
  final DateTime? paymentReportedAt;
  final DateTime? paymentVerifiedAt;
  final String? paymentRejectionReason;
  final DateTime createdAt;
  final BookingReview? review;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final pricing = (json['pricing'] as Map).cast<String, dynamic>();
    final payment = (json['payment'] as Map?)?.cast<String, dynamic>() ?? const {};
    DateTime? parseOrNull(Object? value) =>
        value == null ? null : DateTime.parse(value as String);

    return Booking(
      id: json['id'] as String,
      hotelId: json['hotelId'] as String,
      hallId: json['hallId'] as String,
      hotel: json['hotel'] == null
          ? null
          : BookingHotel.fromJson((json['hotel'] as Map).cast<String, dynamic>()),
      hall: json['hall'] == null
          ? null
          : BookingHall.fromJson((json['hall'] as Map).cast<String, dynamic>()),
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      numberOfGuests: json['numberOfGuests'] as int,
      eventType: json['eventType'] as String,
      specialRequest: json['specialRequest'] as String?,
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String,
      paymentDeadlineAt: parseOrNull(json['paymentDeadlineAt']),
      totalRentCents: pricing['totalRentCents'] as int,
      advancePercent: (pricing['advancePercent'] as num).toDouble(),
      requiredAdvanceCents: pricing['requiredAdvanceCents'] as int,
      reportedAmountCents: payment['reportedAmountCents'] as int?,
      paymentReportedAt: parseOrNull(payment['reportedAt']),
      paymentVerifiedAt: parseOrNull(payment['verifiedAt']),
      paymentRejectionReason: payment['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      review: json['review'] == null
          ? null
          : BookingReview.fromJson((json['review'] as Map).cast<String, dynamic>()),
    );
  }
}

/// A client-side preview of what the backend will charge, using the exact
/// same rule `booking.service.js#calculatePricing` applies server-side
/// (`ceil(durationHours / 24) * rentAmountCents`, advance rounded to the
/// nearest cent) — so the Customer sees the real number before submitting,
/// not a placeholder. The booking response's own `pricing` snapshot is
/// always the authoritative figure once a booking exists; this is only for
/// the pre-submission estimate.
({int totalRentCents, int requiredAdvanceCents}) calculateBookingPricingPreview({
  required DateTime startsAt,
  required DateTime endsAt,
  required int rentAmountCents,
  required double advancePercent,
}) {
  const dayMs = 24 * 60 * 60 * 1000;
  final durationMs = endsAt.difference(startsAt).inMilliseconds;
  final units = (durationMs / dayMs).ceil().clamp(1, 1 << 30);
  final totalRentCents = units * rentAmountCents;
  final requiredAdvanceCents = (totalRentCents * advancePercent / 100).round();
  return (totalRentCents: totalRentCents, requiredAdvanceCents: requiredAdvanceCents);
}
