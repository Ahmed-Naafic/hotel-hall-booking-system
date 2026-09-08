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
      // Android 13+ (API 33+) blocks all notifications for an app until this
      // runtime permission is granted (AndroidManifest.xml declares
      // POST_NOTIFICATIONS) — without it, FCM still delivers messages to the
      // device, but the OS silently drops the system-tray notification.
      await FirebaseMessaging.instance.requestPermission();
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

  /// Fires whenever FCM rotates this device's token (reinstall, cleared app
  /// data, or a security-driven rotation) — the old token silently stops
  /// receiving anything, so whoever holds this stream must re-register the
  /// new value or push quietly goes dead until the next cold start happens
  /// to call [getToken] again on its own. Empty (never emits) when Firebase
  /// isn't configured — same "never throws, degrades to push disabled"
  /// contract as the rest of this service.
  Stream<String> get onTokenRefreshed =>
      _initialized ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  /// Fires when the user taps a system notification while this app is
  /// already running (foreground or background) — never for a cold start
  /// from a terminated app; see [consumeInitialTap] for that case.
  Stream<void> get onNotificationTapped =>
      _initialized ? FirebaseMessaging.onMessageOpenedApp.map((_) {}) : const Stream.empty();

  /// Whether this app launch was itself caused by tapping a system
  /// notification (a terminated-app cold start). Call once, right after
  /// [initialize] — a second call would silently return `false` even for
  /// the same tap (`getInitialMessage` only ever reports it once).
  Future<bool> consumeInitialTap() async {
    if (!_initialized) return false;
    try {
      return await FirebaseMessaging.instance.getInitialMessage() != null;
    } catch (error) {
      debugPrint('[PushNotificationService] Could not read the initial message: $error');
      return false;
    }
  }
}
