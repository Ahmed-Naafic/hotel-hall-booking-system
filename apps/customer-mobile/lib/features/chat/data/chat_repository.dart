import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'chat_models.dart';

/// Communication V1 — the backend is authoritative for persistence,
/// read state, and participant scoping (backend/src/modules/chat); this
/// only forwards requests and parses responses, the same shape
/// `NotificationRepository` already follows.
class ChatRepository {
  ChatRepository(this._client);
  final ApiClient _client;

  /// Oldest first (Business Rule 6 — the opposite order from Notification's
  /// own list), matching the backend's own ordering.
  Future<({List<ChatMessage> messages, bool hasNext, String? nextCursor})> list(
    String bookingId, {
    String? cursor,
    int limit = 50,
  }) async {
    final result = await _client.getPaginated(
      '/bookings/$bookingId/messages',
      query: {'limit': '$limit', if (cursor != null) 'cursor': cursor},
    );
    final messages = (result.data as List)
        .map((item) => ChatMessage.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
    return (
      messages: messages,
      hasNext: result.pagination?['hasNext'] as bool? ?? false,
      nextCursor: result.pagination?['nextCursor'] as String?,
    );
  }

  Future<ChatMessage> send(String bookingId, String body) async {
    final data = await _client.post('/bookings/$bookingId/messages', body: {'body': body});
    return ChatMessage.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> markConversationRead(String bookingId) => _client.post('/bookings/$bookingId/messages/read-all');

  /// Total unread messages across every Booking the caller participates in
  /// (Business Rule 8) — a second, independent badge from Notification's
  /// own unread count, never merged with it.
  Future<int> unreadCount() async {
    final data = await _client.get('/messages/unread-count');
    return (data as Map)['count'] as int;
  }
}
