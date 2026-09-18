import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import 'register_screen.dart';

/// H7/A1 — Hotel Manager login. `BR-AUTH-04`: a Hotel account may log in at
/// any application state; only *operational* features (Hall management,
/// etc. — FE-07, separately blocked on Module 13) are gated, not login
/// itself. Delegates entirely to the shared `LoginForm` (FE-04/FE-06).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              const SizedBox(height: HHSpacing.space12),
              Text('Hotel Hall', style: HHTypography.displayMd, textAlign: TextAlign.center),
              const SizedBox(height: HHSpacing.space1),
              Text(
                'FOR HOTEL MANAGERS',
                style: TextStyle(
                  fontSize: HHTypeScale.eyebrowSize,
                  letterSpacing: HHTypeScale.eyebrowTracking * HHTypeScale.eyebrowSize,
                  fontWeight: HHTypeScale.eyebrowWeight,
                  color: context.hh.textGold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HHSpacing.space4),
              Text(
                'Log in to manage your Hotel',
                style: TextStyle(fontSize: HHTypeScale.textMd, color: context.hh.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HHSpacing.space10),
              LoginForm(
                isBusy: auth.isBusy,
                errorMessage: auth.errorMessage,
                onSubmit: ({required mobileNumber, required password}) {
                  auth.clearError();
                  return auth.login(mobileNumber: mobileNumber, password: password);
                },
              ),
              const SizedBox(height: HHSpacing.space6),
              Center(
                child: TextButton(
                  onPressed: () {
                    auth.clearError();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                  },
                  child: const Text("Don't have a Hotel account? Register"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
