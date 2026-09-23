import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../widgets/hh_error_banner.dart';
import '../../widgets/hh_gold_button.dart';
import '../../widgets/hh_text_field.dart';

/// Login form — C4/H7/A1. Shared verbatim between apps (FE-06's "shares
/// FE-03/FE-04's components"); only the hosting screen's chrome differs.
///
/// The `+252` shown before the mobile field is a decorative hint only
/// (`InputDecoration.prefixText` never joins the typed value) — accounts
/// registered with a bare local number (no country code) still log in with
/// exactly what they type, unchanged from before this field existed.
class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.isBusy,
    this.errorMessage,
  });

  /// Returns `true` on success; the form does not navigate itself.
  final Future<bool> Function({required String mobileNumber, required String password, required bool rememberMe})
  onSubmit;
  final VoidCallback onForgotPassword;
  final bool isBusy;
  final String? errorMessage;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(
      mobileNumber: _mobileController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.errorMessage != null) HHErrorBanner(message: widget.errorMessage!),
          HHTextField(
            label: 'Mobile number',
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            enabled: !widget.isBusy,
            prefixIcon: const Icon(Icons.call_outlined),
            prefixText: '+252 ',
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Mobile number is required.' : null,
          ),
          const SizedBox(height: HHSpacing.space5),
          HHTextField(
            label: 'Password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            enabled: !widget.isBusy,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) => (value == null || value.isEmpty) ? 'Password is required.' : null,
          ),
          const SizedBox(height: HHSpacing.space4),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: widget.isBusy ? null : (value) => setState(() => _rememberMe = value ?? true),
                ),
              ),
              const SizedBox(width: HHSpacing.space2),
              GestureDetector(
                onTap: widget.isBusy ? null : () => setState(() => _rememberMe = !_rememberMe),
                child: Text('Remember me', style: TextStyle(fontSize: HHTypeScale.textSm, color: context.hh.textBody)),
              ),
              const Spacer(),
              // Gold and underlined rather than the app's teal link: on these
              // screens gold is the accent, and an underline is what still
              // says "link" once the colour is carrying brand duty.
              TextButton(
                onPressed: widget.isBusy ? null : widget.onForgotPassword,
                style: TextButton.styleFrom(foregroundColor: context.hh.textGold),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: HHSpacing.space5),
          HHGoldButton(label: 'Log in', isLoading: widget.isBusy, onPressed: _submit),
        ],
      ),
    );
  }
}
