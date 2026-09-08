import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../data/notification_models.dart';
import '../data/notification_repository.dart';

enum NotificationLoadStatus { initial, loading, ready, error }

/// App-wide (registered once in `main.dart`, the same pattern
/// `PopularHotelsController` already established this session) so the
/// unread badge anywhere in the app and the Notification Center screen
/// always agree, without either polling or duplicate fetches — a screen
/// explicitly calls `load()`/`refresh()` on becoming visible; nothing here
/// fetches on a timer.
class NotificationController extends ChangeNotifier {
  NotificationController(this._repository);
  final NotificationRepository _repository;

  NotificationLoadStatus status = NotificationLoadStatus.initial;
  String? errorMessage;
  List<AppNotification> notifications = [];
  bool hasNext = false;
  String? _nextCursor;
  int unreadCount = 0;

  Future<void> load() async {
    status = NotificationLoadStatus.loading;
    notifyListeners();
    try {
      final result = await _repository.list();
      notifications = result.notifications;
      hasNext = result.hasNext;
      _nextCursor = result.nextCursor;
      status = NotificationLoadStatus.ready;
    } on Object catch (error) {
      errorMessage = '$error';
      status = NotificationLoadStatus.error;
    }
    notifyListeners();
    unawaited(refreshUnreadCount());
  }

  Future<void> loadMore() async {
    if (!hasNext) return;
    final result = await _repository.list(cursor: _nextCursor);
    notifications = [...notifications, ...result.notifications];
    hasNext = result.hasNext;
    _nextCursor = result.nextCursor;
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    try {
      unreadCount = await _repository.unreadCount();
      notifyListeners();
    } on Object {
      // The badge is a convenience, not a source of truth — a transient
      // failure here should not surface as an app-wide error state.
    }
  }

  Future<void> markRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1 || notifications[index].status == 'READ') return;
    final updated = await _repository.markRead(id);
    notifications = [
      for (final n in notifications) if (n.id == id) updated else n,
    ];
    unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    notifications = [for (final n in notifications) n.copyWith(status: 'READ', readAt: DateTime.now())];
    unreadCount = 0;
    notifyListeners();
  }

  /// Best-effort — a device without a real FCM token (Firebase not yet
  /// configured, or the platform declined one) has nothing to register;
  /// this is not an app-facing error either way (Business Specification,
  /// push is a delivery mechanism, never a precondition).
  Future<void> registerDeviceToken(String? token) async {
    if (token == null) return;
    try {
      await _repository.registerDeviceToken(token, platform: _currentPlatform());
    } on Object {
      // Best-effort — see doc comment.
    }
  }

  /// Only Android is a real, configured target today (this app has no iOS
  /// Firebase configuration yet — `firebase_options.dart`'s own doc
  /// comment) — `null` on any other platform rather than guessing a value
  /// nothing here actually supports.
  String? _currentPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }

  Future<void> unregisterDeviceToken(String? token) async {
    if (token == null) return;
    try {
      await _repository.unregisterDeviceToken(token);
    } on Object {
      // Best-effort — see doc comment.
    }
  }
}
