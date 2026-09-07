import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../features/discovery/presentation/discover_screen.dart';
import '../features/notifications/application/notification_controller.dart';
import 'push_notification_service.dart';

/// Root routing decision: which screen the app shows for the current
/// `AuthController.status` (and, once authenticated, `currentUser.isVerified`)
/// — never a client-side lifecycle state invented beyond what the API
/// returns (Technical Design §7.1's actual `isActive`/`isVerified` fields).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _deviceTokenRegistered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().restoreSession();
      PushNotificationService.instance.initialize();
    });
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
          backgroundColor: HHColors.surfacePage,
          body: const Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.unauthenticated:
      case AuthStatus.authenticated:
        return const DiscoverScreen();
    }
  }
}
