import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../../../core/sync/local_replica.dart';
import '../../../core/sync/offline_fallback.dart';
import 'chat_models.dart';

/// Communication V1 — the backend is authoritative for persistence,
/// read state, and participant scoping (backend/src/modules/chat); this
/// only forwards requests and parses responses, the same shape
/// `NotificationRepository` already follows.
///
/// Reads fall back to the replica when the server cannot be reached
/// ([serverFirst]). Sending and marking read never do: a message exists once
/// the server has it, and the replica learns of it by syncing.
class ChatRepository {
  ChatRepository(this._client, {this.replica});
  final ApiClient _client;
  final LocalReplica? replica;

  /// Oldest first (Business Rule 6 — the opposite order from Notification's
  /// own list), matching the backend's own ordering.
  Future<({List<ChatMessage> messages, bool hasNext, String? nextCursor})> list(
    String bookingId, {
    String? cursor,
    int limit = 50,
  }) => serverFirst(
    replica,
    online: () => _listOnline(bookingId, cursor: cursor, limit: limit),
    local: (replica) async {
      final store = await replica.readable('chatMessage');
      if (store == null) return null;
      if (cursor != null) {
        return (messages: <ChatMessage>[], hasNext: false, nextCursor: null);
      }
      // Oldest first, the same order the endpoint returns (Business Rule 6).
      final rows = await store.select(
        'chatMessage',
        where: 'booking_id = ?',
        args: [bookingId],
        orderBy: "json_extract(data, '\$.createdAt') ASC, id ASC",
      );
      return (messages: rows.map(ChatMessage.fromJson).toList(), hasNext: false, nextCursor: null);
    },
  );

  Future<({List<ChatMessage> messages, bool hasNext, String? nextCursor})> _listOnline(
    String bookingId, {
    String? cursor,
    required int limit,
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
  ///
  /// Offline: messages someone else sent that are still unread — the replica
  /// holds exactly the conversations this Manager takes part in.
  Future<int> unreadCount() => serverFirst(
    replica,
    online: () async {
      final data = await _client.get('/messages/unread-count');
      return (data as Map)['count'] as int;
    },
    local: (replica) async {
      final me = replica.activeUserId;
      final store = await replica.readable('chatMessage');
      if (store == null || me == null) return null;
      return store.countWhere(
        'chatMessage',
        where: "json_extract(data, '\$.readAt') IS NULL AND json_extract(data, '\$.senderUserId') != ?",
        args: [me],
      );
    },
  );
}
