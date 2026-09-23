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
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeroHeader(tagline: 'Manage your Hotel\'s halls and bookings'),
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
                      'Log in to manage your Hotel',
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
                      onSubmit: ({required mobileNumber, required password, required rememberMe}) {
                        auth.clearError();
                        return auth.login(
                          mobileNumber: mobileNumber,
                          password: password,
                          rememberMe: rememberMe,
                        );
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
                      onPressed: () {
                        auth.clearError();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: HHTypeScale.textMd, color: context.hh.textBody),
                          children: [
                            const TextSpan(text: "Don't have a Hotel account?  "),
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
