/// Notification V1 (backend/src/modules/notifications) — a persisted,
/// user-facing Notification. `bookingId`/`hotelId`/`hotelApplicationId` are
/// independent and nullable; the client uses whichever is present to
/// compute a navigation target (never a server-encoded route string —
/// Approved Technical Design, Notification Management).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.body,
    required this.bookingId,
    required this.hotelId,
    required this.hotelApplicationId,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String status;
  final String title;
  final String body;
  final String? bookingId;
  final String? hotelId;
  final String? hotelApplicationId;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => status == 'UNREAD';

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    type: json['type'] as String,
    status: json['status'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    bookingId: json['bookingId'] as String?,
    hotelId: json['hotelId'] as String?,
    hotelApplicationId: json['hotelApplicationId'] as String?,
    readAt: json['readAt'] == null ? null : DateTime.parse(json['readAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  AppNotification copyWith({String? status, DateTime? readAt}) => AppNotification(
    id: id,
    type: type,
    status: status ?? this.status,
    title: title,
    body: body,
    bookingId: bookingId,
    hotelId: hotelId,
    hotelApplicationId: hotelApplicationId,
    readAt: readAt ?? this.readAt,
    createdAt: createdAt,
  );
}
