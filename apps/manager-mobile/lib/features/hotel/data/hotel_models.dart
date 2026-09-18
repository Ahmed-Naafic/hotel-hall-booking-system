/// Mirrors `openapi.json#/components/schemas/PublicHotel` exactly — no
/// field invented, none omitted. `status` is the backend's own raw value
/// (e.g. `APPROVED_ACTIVE`) — this app never re-derives or renames it.
class Hotel {
  const Hotel({
    required this.id,
    required this.registeredByUserId,
    required this.status,
    required this.profileData,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String registeredByUserId;
  final String status;
  final Map<String, dynamic>? profileData;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Hotel.fromJson(Map<String, dynamic> json) => Hotel(
    id: json['id'] as String,
    registeredByUserId: json['registeredByUserId'] as String,
    status: json['status'] as String,
    profileData: (json['profileData'] as Map?)?.cast<String, dynamic>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class HotelApplication {
  const HotelApplication({
    required this.id,
    required this.hotelId,
    required this.status,
    required this.submittedAt,
    this.decidedByUserId,
    this.decidedAt,
    this.decisionReason,
  });

  final String id;
  final String hotelId;
  final String status;
  final String? decidedByUserId;
  final DateTime? decidedAt;
  final String? decisionReason;
  final DateTime submittedAt;

  factory HotelApplication.fromJson(Map<String, dynamic> json) =>
      HotelApplication(
        id: json['id'] as String,
        hotelId: json['hotelId'] as String,
        status: json['status'] as String,
        decidedByUserId: json['decidedByUserId'] as String?,
        decidedAt: json['decidedAt'] == null
            ? null
            : DateTime.parse(json['decidedAt'] as String),
        decisionReason: json['decisionReason'] as String?,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
      );
}

class MyHotelSnapshot {
  const MyHotelSnapshot({required this.hotel, required this.latestApplication, required this.reviewSummary});

  final Hotel? hotel;
  final HotelApplication? latestApplication;
  final ReviewSummary? reviewSummary;

  factory MyHotelSnapshot.fromJson(Map<String, dynamic> json) =>
      MyHotelSnapshot(
        hotel: json['hotel'] == null
            ? null
            : Hotel.fromJson((json['hotel'] as Map).cast<String, dynamic>()),
        latestApplication: json['latestApplication'] == null
            ? null
            : HotelApplication.fromJson(
                (json['latestApplication'] as Map).cast<String, dynamic>(),
              ),
        reviewSummary: json['reviewSummary'] == null
            ? null
            : ReviewSummary.fromJson((json['reviewSummary'] as Map).cast<String, dynamic>()),
      );
}

/// A Hotel's real average rating and review count (`GET /hotels/me`'s
/// `reviewSummary`) — the same aggregate the public Hotel Detail endpoint
/// already exposes to Customers. `average` is `null` (not `0`) when the
/// Hotel has zero reviews.
class ReviewSummary {
  const ReviewSummary({required this.average, required this.count});

  final double? average;
  final int count;

  factory ReviewSummary.fromJson(Map<String, dynamic> json) => ReviewSummary(
    average: (json['average'] as num?)?.toDouble(),
    count: json['count'] as int,
  );
}

/// Mirrors `openapi.json#/components/schemas/PublicHotelMedia` exactly
/// (`BDR-015`, `ADR-0006`, Hotel Management Technical Design §8a). `url` is
/// a stable, non-expiring public URL derived server-side at read time —
/// this app never constructs or caches a storage path itself.
class HotelMedia {
  const HotelMedia({
    required this.id,
    required this.hotelId,
    required this.type,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String hotelId;
  final String type;
  final String url;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory HotelMedia.fromJson(Map<String, dynamic> json) => HotelMedia(
    id: json['id'] as String,
    hotelId: json['hotelId'] as String,
    type: json['type'] as String,
    url: json['url'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// The `{ logo, photos }` shape `GET /hotels/:hotelId/media` returns.
class HotelMediaCollection {
  const HotelMediaCollection({required this.logo, required this.photos});

  final HotelMedia? logo;
  final List<HotelMedia> photos;

  factory HotelMediaCollection.fromJson(Map<String, dynamic> json) =>
      HotelMediaCollection(
        logo: json['logo'] == null
            ? null
            : HotelMedia.fromJson(
                (json['logo'] as Map).cast<String, dynamic>(),
              ),
        photos: (json['photos'] as List<dynamic>? ?? const [])
            .map((e) => HotelMedia.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}
