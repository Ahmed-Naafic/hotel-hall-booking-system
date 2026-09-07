import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/notification_models.dart';
import '../data/notification_repository.dart';

enum NotificationLoadStatus { initial, loading, ready, error }

/// App-wide (registered once in `main.dart`) so the unread badge and the
/// Notification Center screen always agree, without polling — a screen
/// explicitly calls `load()`/`refresh()` on becoming visible.
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
}
