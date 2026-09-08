import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../widgets/hh_error_banner.dart';
import '../../widgets/hh_primary_button.dart';
import '../../widgets/hh_text_field.dart';

/// Registration form — C2/H1, BR-AUTH-02/03. `accountType` is fixed by the
/// hosting app (`CUSTOMER` for Customer Mobile, `HOTEL_MANAGER` for Manager
/// Mobile), never user-chosen — self-registration only ever creates one of
/// those two types, and each app already knows which. Only the fields the
/// backend actually accepts are collected — no `confirmPassword` or other
/// field the API doesn't define.
///
/// [requireFullName] (BDR-018) shows and requires a Full Name field ahead of
/// Mobile number — Customer Mobile passes `true`; Hotel registration is
/// unaffected by that decision and leaves this at its default `false`.
class RegisterForm extends StatefulWidget {
  const RegisterForm({
    super.key,
    required this.onSubmit,
    required this.isBusy,
    this.errorMessage,
    this.requireFullName = false,
  });

  /// Returns `true` on success (caller navigates away); the form does not
  /// navigate itself. `fullName` is non-null only when [requireFullName] is
  /// true — a caller that leaves it `false` may safely ignore the parameter.
  final Future<bool> Function({required String mobileNumber, required String password, String? fullName}) onSubmit;
  final bool isBusy;
  final String? errorMessage;
  final bool requireFullName;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(
      mobileNumber: _mobileController.text.trim(),
      password: _passwordController.text,
      fullName: widget.requireFullName ? _fullNameController.text.trim() : null,
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
          if (widget.requireFullName) ...[
            HHTextField(
              label: 'Full name',
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              enabled: !widget.isBusy,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Full name is required.';
                return null;
              },
            ),
            const SizedBox(height: HHSpacing.space5),
          ],
          HHTextField(
            label: 'Mobile number',
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            enabled: !widget.isBusy,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Mobile number is required.';
              if (!RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(v)) {
                return 'Enter a valid mobile number.';
              }
              return null;
            },
          ),
          const SizedBox(height: HHSpacing.space5),
          HHTextField(
            label: 'Password',
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            enabled: !widget.isBusy,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required.';
              if (value.length < 8) return 'Password must be at least 8 characters.';
              return null;
            },
          ),
          const SizedBox(height: HHSpacing.space7),
          HHPrimaryButton(label: 'Create account', isLoading: widget.isBusy, onPressed: _submit),
        ],
      ),
    );
  }
}
