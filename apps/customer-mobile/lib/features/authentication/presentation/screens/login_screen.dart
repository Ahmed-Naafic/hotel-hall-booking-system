import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import 'register_screen.dart';
import 'verify_screen.dart';

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
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeroHeader(tagline: 'Book the perfect hall for your next event'),
              Container(
                decoration: BoxDecoration(
                  color: context.hh.surfaceCard,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(HHRadii.xl2),
                    topRight: Radius.circular(HHRadii.xl2),
                  ),
                ),
                transform: Matrix4.translationValues(0, -HHSpacing.space6, 0),
                padding: const EdgeInsets.fromLTRB(
                  HHSpacing.space7,
                  HHSpacing.space8,
                  HHSpacing.space7,
                  HHSpacing.space8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: HHTypography.displaySm.copyWith(color: context.hh.textHeading),
                    ),
                    const SizedBox(height: HHSpacing.space2),
                    Text(
                      'Log in to book your next event',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: HHTypeScale.textMd, color: context.hh.textMuted),
                    ),
                    const SizedBox(height: HHSpacing.space8),
                    LoginForm(
                      isBusy: auth.isBusy,
                      errorMessage: auth.errorMessage,
                      onForgotPassword: () {
                        auth.clearError();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen(repository: auth.repository),
                          ),
                        );
                      },
                      onSubmit: ({required mobileNumber, required password, required rememberMe}) async {
                        auth.clearError();
                        final ok = await auth.login(
                          mobileNumber: mobileNumber,
                          password: password,
                          rememberMe: rememberMe,
                        );
                        if (!ok || !context.mounted) return ok;
                        // A correct password no longer signs anyone in on its
                        // own: the backend texts a code and issues nothing
                        // until it comes back, so this hands over to the code
                        // screen and only reports success once a session
                        // actually exists.
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
                    const SizedBox(height: HHSpacing.space6),
                    Row(
                      children: [
                        Expanded(child: Divider(color: context.hh.borderSubtle)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: HHSpacing.space4),
                          child: Text(
                            'OR',
                            style: TextStyle(fontSize: HHTypeScale.textXs, color: context.hh.textSubtle),
                          ),
                        ),
                        Expanded(child: Divider(color: context.hh.borderSubtle)),
                      ],
                    ),
                    const SizedBox(height: HHSpacing.space6),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.hh.borderGold),
                        padding: const EdgeInsets.symmetric(vertical: HHSpacing.space4),
                      ),
                      onPressed: () async {
                        auth.clearError();
                        final registered = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                        // Registering signs the Customer in, so this screen
                        // has nothing left to ask for — close it too,
                        // reporting the same success to whoever pushed it.
                        if (registered == true && context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: HHTypeScale.textMd, color: context.hh.textBody),
                          children: [
                            const TextSpan(text: "Don't have an account?  "),
                            TextSpan(
                              text: 'Register  →',
                              style: TextStyle(color: context.hh.textGold, fontWeight: HHTypeScale.weightMedium),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: HHSpacing.space9),
                    const AuthFeatureHighlights(),
                    const SizedBox(height: HHSpacing.space9),
                    const AuthFooterTagline(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
