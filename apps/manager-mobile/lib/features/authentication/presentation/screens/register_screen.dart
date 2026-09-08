import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

/// H1 — Hotel account creation. `accountType` is fixed to `HOTEL_MANAGER`
/// (BR-AUTH-03) — never user-chosen. Delegates to the shared `RegisterForm`
/// (FE-06). Hotel business-profile completion (Hotel Management, Module 3)
/// is out of this screen's scope (Business Specification §2.2) — this
/// screen only creates the account/credentials.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: const Text('Register Your Hotel')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create your Hotel Manager account to start onboarding your Hotel.',
                style: TextStyle(fontSize: HHTypeScale.textMd, color: HHColors.textMuted),
              ),
              const SizedBox(height: HHSpacing.space7),
              RegisterForm(
                isBusy: auth.isBusy,
                errorMessage: auth.errorMessage,
                onSubmit: ({required mobileNumber, required password, fullName}) async {
                  auth.clearError();
                  final ok = await auth.registerAndRequestVerification(
                    mobileNumber: mobileNumber,
                    password: password,
                    accountType: 'HOTEL_MANAGER',
                  );
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
