import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

/// C2 — Customer registration. `accountType` is fixed to `CUSTOMER`
/// (BR-AUTH-03) — never user-chosen. Delegates to the shared `RegisterForm`
/// (FE-03).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Register with your mobile number to start booking Halls.',
                style: TextStyle(fontSize: HHTypeScale.textMd, color: HHColors.textMuted),
              ),
              const SizedBox(height: HHSpacing.space7),
              RegisterForm(
                isBusy: auth.isBusy,
                errorMessage: auth.errorMessage,
                onSubmit: ({required mobileNumber, required password}) async {
                  auth.clearError();
                  final ok = await auth.registerAndRequestVerification(
                    mobileNumber: mobileNumber,
                    password: password,
                    accountType: 'CUSTOMER',
                  );
                  // On success the app becomes authenticated-but-unverified;
                  // pop back to the root so AuthGate can show VerifyScreen —
                  // this pushed route would otherwise stay on top of it.
                  if (ok && context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                  return ok;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
