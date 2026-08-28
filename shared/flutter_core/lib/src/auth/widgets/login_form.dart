import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../widgets/hh_error_banner.dart';
import '../../widgets/hh_primary_button.dart';
import '../../widgets/hh_text_field.dart';

/// Login form — C4/H7/A1. Shared verbatim between apps (FE-06's "shares
/// FE-03/FE-04's components"); only the hosting screen's chrome differs.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onSubmit, required this.isBusy, this.errorMessage});

  /// Returns `true` on success; the form does not navigate itself.
  final Future<bool> Function({required String mobileNumber, required String password}) onSubmit;
  final bool isBusy;
  final String? errorMessage;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(mobileNumber: _mobileController.text.trim(), password: _passwordController.text);
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
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Mobile number is required.' : null,
          ),
          const SizedBox(height: HHSpacing.space5),
          HHTextField(
            label: 'Password',
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            enabled: !widget.isBusy,
            validator: (value) => (value == null || value.isEmpty) ? 'Password is required.' : null,
          ),
          const SizedBox(height: HHSpacing.space7),
          HHPrimaryButton(label: 'Log in', isLoading: widget.isBusy, onPressed: _submit),
        ],
      ),
    );
  }
}
