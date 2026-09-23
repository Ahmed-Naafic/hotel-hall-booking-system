import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../widgets/hh_error_banner.dart';
import '../../widgets/hh_gold_button.dart';
import '../../widgets/hh_text_field.dart';

/// Mobile-number verification form — C3, BR-AUTH-02. A 6-digit code, per
/// the backend's own shape validation (`authentication.validation.js`
/// `VERIFICATION_CODE_PATTERN`), plus a resend action (`POST
/// /auth/verifications` again).
class VerifyForm extends StatefulWidget {
  const VerifyForm({
    super.key,
    required this.onSubmit,
    required this.onResend,
    required this.isBusy,
    required this.isResending,
    this.errorMessage,
  });

  final Future<bool> Function(String code) onSubmit;
  final Future<bool> Function() onResend;
  final bool isBusy;
  final bool isResending;
  final String? errorMessage;

  @override
  State<VerifyForm> createState() => _VerifyFormState();
}

class _VerifyFormState extends State<VerifyForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(_codeController.text.trim());
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
            label: 'Verification code',
            controller: _codeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            enabled: !widget.isBusy,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Enter the 6-digit code.';
              return null;
            },
          ),
          const SizedBox(height: HHSpacing.space7),
          HHGoldButton(label: 'Verify', isLoading: widget.isBusy, onPressed: _submit),
          const SizedBox(height: HHSpacing.space4),
          TextButton(
            onPressed: widget.isResending ? null : () => widget.onResend(),
            child: Text(widget.isResending ? 'Sending…' : "Didn't get a code? Resend"),
          ),
        ],
      ),
    );
  }
}
