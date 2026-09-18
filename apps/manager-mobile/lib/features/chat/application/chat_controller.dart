import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/chat_models.dart';
import '../data/chat_repository.dart';

enum ChatLoadStatus { initial, loading, ready, error }

/// Scoped to one open conversation (created per `ChatScreen` instance, never
/// app-wide like `NotificationController`) — a conversation is opened, used,
/// and closed, not a persistent badge source by itself (Technical Design
/// "Client Architecture (Both Mobile Apps)").
class ChatController extends ChangeNotifier {
  ChatController(this._repository, this.bookingId);
  final ChatRepository _repository;
  final String bookingId;

  ChatLoadStatus status = ChatLoadStatus.initial;
  String? errorMessage;
  List<ChatMessage> messages = [];
  bool isSending = false;

  Future<void> load() async {
    status = ChatLoadStatus.loading;
    notifyListeners();
    try {
      final result = await _repository.list(bookingId);
      messages = result.messages;
      status = ChatLoadStatus.ready;
    } on Object catch (error) {
      errorMessage = '$error';
      status = ChatLoadStatus.error;
      notifyListeners();
      return;
    }
    notifyListeners();
    // Opening the conversation marks every message from the other
    // participant read (Business Rule 7) — best-effort; a transient
    // failure here should not block the conversation from being readable.
    unawaited(_repository.markConversationRead(bookingId).catchError((_) {}));
  }

  Future<void> send(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || isSending) return;
    isSending = true;
    notifyListeners();
    try {
      final message = await _repository.send(bookingId, trimmed);
      messages = [...messages, message];
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
