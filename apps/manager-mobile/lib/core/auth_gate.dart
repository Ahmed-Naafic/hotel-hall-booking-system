import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../features/authentication/presentation/screens/home_screen.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/verify_screen.dart';
import '../features/notifications/application/notification_controller.dart';
import '../features/notifications/presentation/screens/notification_center_screen.dart';
import 'push_notification_service.dart';

/// Root routing decision — identical structure to Customer Mobile's own
/// `AuthGate` (FE-06 shares FE-03/FE-04's components, including this
/// composition pattern); never a client-side lifecycle state invented
/// beyond the real `isActive`/`isVerified` API fields.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _deviceTokenRegistered = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<void>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    final authController = context.read<AuthController>();
    final notificationController = context.read<NotificationController>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      authController.restoreSession();
      await PushNotificationService.instance.initialize();
      _tokenRefreshSubscription = PushNotificationService.instance.onTokenRefreshed.listen((token) {
        notificationController.registerDeviceToken(token);
      });
      _tapSubscription = PushNotificationService.instance.onNotificationTapped.listen((_) {
        if (mounted) _openNotificationCenter();
      });
      if (await PushNotificationService.instance.consumeInitialTap() && mounted) {
        _openNotificationCenter();
      }
    });
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tapSubscription?.cancel();
    super.dispose();
  }

  /// Both a tapped background/foreground notification ([onNotificationTapped])
  /// and a tapped cold-start one ([consumeInitialTap]) land here — reusing
  /// the Notification Center's own existing tap-to-navigate behavior
  /// (Business Specification, Rule: tap-to-navigate) rather than resolving
  /// a route per Notification type a second time in a different place.
  void _openNotificationCenter() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationCenterScreen()));
  }

  /// Registers this device's FCM token once per authenticated session —
  /// never on every rebuild, and never for a Visitor (Business
  /// Specification, a token belongs to an authenticated recipient). Safe to
  /// call repeatedly: `PushNotificationService.getToken()` and
  /// `NotificationController.registerDeviceToken()` are both no-ops when
  /// there is nothing to register (Firebase not configured, or already done).
  Future<void> _ensureDeviceTokenRegistered(BuildContext context) async {
    if (_deviceTokenRegistered) return;
    _deviceTokenRegistered = true;
    final token = await PushNotificationService.instance.getToken();
    if (!context.mounted) return;
    await context.read<NotificationController>().registerDeviceToken(token);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (auth.status == AuthStatus.authenticated) {
      _ensureDeviceTokenRegistered(context);
    }

    switch (auth.status) {
      case AuthStatus.unknown:
        return Scaffold(
          backgroundColor: context.hh.surfacePage,
          body: const Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return auth.currentUser?.isVerified == true ? const HomeScreen() : const VerifyScreen();
    }
  }
}
