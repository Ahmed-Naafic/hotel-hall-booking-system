import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/push_notification_service.dart';
import '../../../notifications/application/notification_controller.dart';

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
                  color: HHColors.textMuted,
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
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                  return ok;
                },
                onResend: () {
                  auth.clearError();
                  return auth.resendVerificationCode();
                },
              ),
              const SizedBox(height: HHSpacing.space6),
              Center(
                child: TextButton(
                  onPressed: () async {
                    // Best-effort — unregister this device's push token
                    // before the session that authorized it goes away, so
                    // a shared device never keeps receiving this account's
                    // notifications after logging out.
                    final token = await PushNotificationService.instance.getToken();
                    if (context.mounted) {
                      await context.read<NotificationController>().unregisterDeviceToken(token);
                    }
                    await auth.logout();
                  },
                  child: const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
