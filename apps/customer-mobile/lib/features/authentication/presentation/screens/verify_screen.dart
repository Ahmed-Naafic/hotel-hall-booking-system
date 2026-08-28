import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

/// C3 — mobile-number verification. Rendered by `AuthGate` whenever the
/// authenticated user's `isVerified` is `false` — never a separate route
/// pushed onto the stack, so there is nothing to navigate back out of.
class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
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
                'We sent a 6-digit code to ${auth.currentUser?.mobileNumber ?? 'your mobile number'}.',
                style: TextStyle(fontSize: HHTypeScale.textMd, color: HHColors.textMuted),
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
                child: TextButton(onPressed: auth.logout, child: const Text('Log out')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
