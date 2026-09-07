import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Notification V1 (ADR-0001, Firebase Cloud Messaging) — the only file in
/// this app that touches the Firebase SDK directly; every other file goes
/// through this service. `initialize()` never throws: a device/build
/// without real Firebase configuration (or a first run before the
/// developer has added `google-services.json`) must not crash the rest of
/// the app — push delivery is a best-effort side channel, never a
/// precondition for anything else working (Business Specification, Rule
/// 14/15).
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      // Foreground messages: Notification Center is the in-app treatment
      // (mobile-application-architecture.md §11) — the unread badge is
      // refreshed by whoever already holds a NotificationController
      // reference next time they touch it; this service does not reach
      // into Provider itself (architecture-principles.md §5, no reaching
      // across layers it doesn't own).
      FirebaseMessaging.onMessage.listen((_) {});
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('[PushNotificationService] Firebase unavailable, push delivery disabled: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// `null` if Firebase isn't initialized (not configured yet) or the
  /// platform/device declined a token — callers must treat that as "no
  /// token to register today," never an error.
  Future<String?> getToken() async {
    if (!_initialized) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('[PushNotificationService] Could not obtain a device token: $error');
      return null;
    }
  }
}
