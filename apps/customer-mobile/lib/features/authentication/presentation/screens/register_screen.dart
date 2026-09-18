import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import 'verify_screen.dart';

/// C2 — Customer registration. `accountType` is fixed to `CUSTOMER`
/// (BR-AUTH-03) — never user-chosen. Delegates to the shared `RegisterForm`
/// (FE-03).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Register with your mobile number to start booking Halls.',
                style: TextStyle(
                  fontSize: HHTypeScale.textMd,
                  color: context.hh.textMuted,
                ),
              ),
              const SizedBox(height: HHSpacing.space7),
              RegisterForm(
                isBusy: auth.isBusy,
                errorMessage: auth.errorMessage,
                requireFullName: true,
                onSubmit: ({required mobileNumber, required password, fullName}) async {
                  auth.clearError();
                  final ok = await auth.registerAndRequestVerification(
                    mobileNumber: mobileNumber,
                    password: password,
                    accountType: 'CUSTOMER',
                    fullName: fullName,
                  );
                  if (!ok || !context.mounted) return ok;
                  // Registering no longer signs anyone in either: it ends at
                  // the same texted code login does, so both flows meet on
                  // the same screen and only report success once a session
                  // exists.
                  if (auth.awaitingLoginCode) {
                    final verified = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const VerifyScreen()),
                    );
                    if (verified == true && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                    return verified == true;
                  }
                  Navigator.of(context).pop(true);
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
