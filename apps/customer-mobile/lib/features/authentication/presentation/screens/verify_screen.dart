import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

/// C3 — mobile-number verification. Pushed as a route by whichever flow
/// requires a verified Customer (booking a Hall being the first), and pops
/// itself with `true` once the code is confirmed so that flow can carry on
/// from where it left off.
class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});

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
              Text(
                'Verify your mobile number',
                style: HHTypography.displaySm,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HHSpacing.space3),
              Text(
                'We sent a 6-digit code to ${auth.currentUser?.mobileNumber ?? 'your mobile number'}.',
                style: TextStyle(
                  fontSize: HHTypeScale.textMd,
                  color: context.hh.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HHSpacing.space10),
              VerifyForm(
                isBusy: auth.isBusy,
                isResending: auth.isBusy,
                errorMessage: auth.errorMessage,
                onSubmit: (code) async {
                  auth.clearError();
                  final ok = await auth.confirmVerification(code);
                  if (ok && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                  return ok;
                },
                onResend: () {
                  auth.clearError();
                  return auth.resendVerificationCode();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
