import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../features/discovery/presentation/discover_screen.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

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
