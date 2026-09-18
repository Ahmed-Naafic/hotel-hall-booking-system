import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import 'register_screen.dart';

/// C4 — Customer login. Delegates entirely to the shared `LoginForm`
/// (FE-04); this screen only supplies Customer-specific chrome/copy and
/// wires the shared `AuthController`.
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
              Text(
                'Hotel Hall',
                style: HHTypography.displayMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HHSpacing.space2),
              Text(
                'Log in to book your next event',
                style: TextStyle(
                  fontSize: HHTypeScale.textMd,
                  color: context.hh.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HHSpacing.space10),
              LoginForm(
                isBusy: auth.isBusy,
                errorMessage: auth.errorMessage,
                onSubmit: ({required mobileNumber, required password}) async {
                  auth.clearError();
                  final ok = await auth.login(
                    mobileNumber: mobileNumber,
                    password: password,
                  );
                  if (ok && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                  return ok;
                },
              ),
              const SizedBox(height: HHSpacing.space6),
              Center(
                child: TextButton(
                  onPressed: () async {
                    auth.clearError();
                    final registered = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                    // Registering signs the Customer in, so this screen has
                    // nothing left to ask for — close it too, reporting the
                    // same success to whoever pushed it.
                    if (registered == true && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text("Don't have an account? Register"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
