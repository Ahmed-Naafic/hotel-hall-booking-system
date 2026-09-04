class MediaItem {
  const MediaItem({required this.url});
  final String url;
  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      MediaItem(url: json['url'] as String);
}

class HotelSummary {
  const HotelSummary({
    required this.id,
    required this.profileData,
    this.logo,
    this.photos = const [],
  });
  final String id;
  final Map<String, dynamic> profileData;
  final MediaItem? logo;
  final List<MediaItem> photos;
  String get name => profileData['name'] as String? ?? 'Hotel';
  String get description => profileData['description'] as String? ?? '';
  String get location {
    final value = profileData['location'];
    if (value is String) return value;
    if (value is Map) return value['address']?.toString() ?? '';
    return '';
  }

  double? get latitude => (profileData['location'] is Map)
      ? ((profileData['location'] as Map)['latitude'] as num?)?.toDouble()
      : null;
  double? get longitude => (profileData['location'] is Map)
      ? ((profileData['location'] as Map)['longitude'] as num?)?.toDouble()
      : null;

  factory HotelSummary.fromJson(Map<String, dynamic> json) => HotelSummary(
    id: json['id'] as String,
    profileData: (json['profileData'] as Map?)?.cast<String, dynamic>() ?? {},
    logo: json['logo'] == null
        ? null
        : MediaItem.fromJson((json['logo'] as Map).cast<String, dynamic>()),
    photos: ((json['photos'] as List?) ?? [])
        .map(
          (item) => MediaItem.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(),
  );
}

class HallSummary {
  const HallSummary({
    required this.id,
    required this.hotelId,
    required this.profileData,
    this.photos = const [],
    this.bookingTerms = const {},
  });
  final String id;
  final String hotelId;
  final Map<String, dynamic> profileData;
  final List<MediaItem> photos;
  final Map<String, dynamic> bookingTerms;
  String get name => profileData['name'] as String? ?? 'Hall';
  String get description => profileData['description'] as String? ?? '';
  String get location =>
      (profileData['location'] ?? profileData['area']) as String? ?? '';
  String get capacity => profileData['capacity']?.toString() ?? '';
  int? get rentAmountCents => bookingTerms['rentAmountCents'] as int?;
  int get rentDurationHours => bookingTerms['rentDurationHours'] as int? ?? 24;
  double? get advancePaymentPercent =>
      (bookingTerms['advancePaymentPercent'] as num?)?.toDouble();
  String get paymentReceivingNumber =>
      bookingTerms['paymentReceivingNumber'] as String? ?? '';
  String get customerServiceNumber =>
      bookingTerms['customerServiceNumber'] as String? ?? '';

  factory HallSummary.fromJson(Map<String, dynamic> json) => HallSummary(
    id: json['id'] as String,
    hotelId: json['hotelId'] as String,
    profileData: (json['profileData'] as Map?)?.cast<String, dynamic>() ?? {},
    bookingTerms: (json['bookingTerms'] as Map?)?.cast<String, dynamic>() ?? {},
    photos: ((json['photos'] as List?) ?? [])
        .map(
          (item) => MediaItem.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(),
  );
}
