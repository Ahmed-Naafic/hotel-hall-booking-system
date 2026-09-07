import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'notification_models.dart';

/// Notification V1 — the backend is authoritative for persistence,
/// read/unread state, and recipient scoping; this only forwards requests
/// and parses responses (backend/src/modules/notifications).
class NotificationRepository {
  NotificationRepository(this._client);
  final ApiClient _client;

  Future<({List<AppNotification> notifications, bool hasNext, String? nextCursor})> list({
    String? cursor,
    int limit = 20,
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

  Future<int> unreadCount() async {
    final data = await _client.get('/notifications/unread-count');
    return (data as Map)['count'] as int;
  }

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
