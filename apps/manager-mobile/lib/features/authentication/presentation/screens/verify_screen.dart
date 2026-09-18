import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../hotel/application/hotel_context_controller.dart';

/// Mobile-number verification for a Hotel Manager account — same mechanism
/// as Customer Mobile's C3 (BR-AUTH-02 applies identically to every
/// self-registered account type). Rendered by `AuthGate` whenever the
/// authenticated user's `isVerified` is `false`, and during sign-in
/// while the texted login code is outstanding.
class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthController>();
    final hotelContext = context.read<HotelContextController>();
    await auth.logout();
    await hotelContext.clearOnLogout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HHSpacing.space10),
              Text('Verify your mobile number', style: HHTypography.displaySm, textAlign: TextAlign.center),
              const SizedBox(height: HHSpacing.space3),
              Text(
                'We sent a 6-digit code to ${auth.pendingMobileNumber ?? auth.currentUser?.mobileNumber ?? 'your mobile number'}.',
                style: TextStyle(fontSize: HHTypeScale.textMd, color: context.hh.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HHSpacing.space10),
              VerifyForm(
                isBusy: auth.isBusy,
                isResending: auth.isBusy,
                errorMessage: auth.errorMessage,
                onSubmit: (code) {
                  auth.clearError();
                  return auth.confirmVerification(code);
                },
                onResend: () {
                  auth.clearError();
                  return auth.resendVerificationCode();
                },
              ),
              const SizedBox(height: HHSpacing.space6),
              Center(
                child: TextButton(onPressed: () => _logout(context), child: const Text('Log out')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
