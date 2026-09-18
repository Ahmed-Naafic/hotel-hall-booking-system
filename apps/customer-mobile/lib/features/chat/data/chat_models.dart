/// Communication V1 (backend/src/modules/chat) — one message in a Booking's
/// conversation. No `bookingId` here — the caller already knows which
/// conversation this is (it's in the URL), the same omit-the-obvious
/// convention `AppNotification` follows.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderUserId,
    required this.body,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final String senderUserId;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    senderUserId: json['senderUserId'] as String,
    body: json['body'] as String,
    readAt: json['readAt'] == null ? null : DateTime.parse(json['readAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
