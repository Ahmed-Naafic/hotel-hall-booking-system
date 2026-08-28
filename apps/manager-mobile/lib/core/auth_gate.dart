import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../features/authentication/presentation/screens/home_screen.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/verify_screen.dart';

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
        return const LoginScreen();
      case AuthStatus.authenticated:
        return auth.currentUser?.isVerified == true ? const HomeScreen() : const VerifyScreen();
    }
  }
}
