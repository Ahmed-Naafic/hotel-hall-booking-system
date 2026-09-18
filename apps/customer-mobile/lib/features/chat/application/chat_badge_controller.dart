import 'package:flutter/foundation.dart';

import '../data/chat_repository.dart';

/// App-wide unread-message count (Business Rule 8) — a second, independent
/// badge from `NotificationController`'s own unread count, never merged
/// with it. Mirrors `NotificationController`'s own shallow refresh model:
/// the count only ever changes because something explicitly calls
/// [refresh] (never a poll).
class ChatBadgeController extends ChangeNotifier {
  ChatBadgeController(this._repository);
  final ChatRepository _repository;

  int unreadCount = 0;

  Future<void> refresh() async {
    try {
      unreadCount = await _repository.unreadCount();
      notifyListeners();
    } on Object {
      // The badge is a convenience, not a source of truth — a transient
      // failure here should not surface as an app-wide error state (same
      // rationale as NotificationController.refreshUnreadCount).
    }
  }
}
