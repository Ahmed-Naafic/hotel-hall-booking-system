import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../../../core/sync/local_replica.dart';
import '../../../core/sync/offline_fallback.dart';
import 'notification_models.dart';

/// Notification V1 — the backend is authoritative for persistence,
/// read/unread state, and recipient scoping; this only forwards requests
/// and parses responses (backend/src/modules/notifications).
///
/// Reads fall back to the replica when the server cannot be reached
/// ([serverFirst]); marking read never does — the row is the source of truth
/// (Notification V1, Rule 2/13), so the change is made on the server and
/// reaches the replica by syncing.
class NotificationRepository {
  NotificationRepository(this._client, {this.replica});
  final ApiClient _client;
  final LocalReplica? replica;

  /// Offline, the replicated Notifications newest first, in one page: the
  /// server's cursors mean nothing to the replica, and the replica holds them
  /// all, so there is no next page to fetch.
  Future<({List<AppNotification> notifications, bool hasNext, String? nextCursor})> list({
    String? cursor,
    int limit = 20,
    String? status,
  }) => serverFirst(
    replica,
    online: () => _listOnline(cursor: cursor, limit: limit, status: status),
    local: (replica) async {
      final store = await replica.readable('notification');
      if (store == null) return null;
      // A "next page" request offline: the first page already held everything.
      if (cursor != null) {
        return (notifications: <AppNotification>[], hasNext: false, nextCursor: null);
      }
      final rows = await store.select(
        'notification',
        where: status == null ? null : "json_extract(data, '\$.status') = ?",
        args: [?status],
        orderBy: "json_extract(data, '\$.createdAt') DESC, id DESC",
      );
      return (
        notifications: rows.map(AppNotification.fromJson).toList(),
        hasNext: false,
        nextCursor: null,
      );
    },
  );

  Future<({List<AppNotification> notifications, bool hasNext, String? nextCursor})> _listOnline({
    String? cursor,
    required int limit,
    String? status,
  }) async {
    final result = await _client.getPaginated(
      '/notifications',
      query: {'limit': '$limit', if (cursor != null) 'cursor': cursor, if (status != null) 'status': status},
    );
    final notifications = (result.data as List)
        .map((item) => AppNotification.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
    return (
      notifications: notifications,
      hasNext: result.pagination?['hasNext'] as bool? ?? false,
      nextCursor: result.pagination?['nextCursor'] as String?,
    );
  }

  Future<int> unreadCount() => serverFirst(
    replica,
    online: () async {
      final data = await _client.get('/notifications/unread-count');
      return (data as Map)['count'] as int;
    },
    local: (replica) async => (await replica.readable('notification'))
        ?.countWhere('notification', where: "json_extract(data, '\$.status') = 'UNREAD'"),
  );

  Future<AppNotification> markRead(String id) async {
    final data = await _client.post('/notifications/$id/read');
    return AppNotification.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> markAllRead() => _client.post('/notifications/read-all');

  Future<void> registerDeviceToken(String token, {String? platform}) =>
      _client.put('/notifications/device-tokens', body: {'token': token, if (platform != null) 'platform': platform});

  /// `token` goes as a query parameter, not a URL path segment or a
  /// request body — an FCM token's character set is not guaranteed
  /// URL-path-safe, and `ApiClient.delete` doesn't support a body.
  Future<void> unregisterDeviceToken(String token) =>
      _client.delete('/notifications/device-tokens?token=${Uri.encodeQueryComponent(token)}');
}
