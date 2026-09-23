import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../../api/api_exception.dart';
import '../../widgets/hh_error_banner.dart';
import '../../widgets/hh_gold_button.dart';
import '../../widgets/hh_text_field.dart';
import '../auth_repository.dart';

/// Forgot password (C6, BR-AUTH-09) — `POST /auth/password-resets` then
/// `PATCH /auth/password-resets`. One screen, shared as-is between Customer
/// and Hotel Manager Mobile: unlike Login/Register/Verify this flow carries
/// no app-specific copy at all (same account model, same two endpoints), so
/// there is nothing for a per-app wrapper screen to add.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { requestCode, confirmReset }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _requestFormKey = GlobalKey<FormState>();
  final _confirmFormKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  _Step _step = _Step.requestCode;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _mobileController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_requestFormKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.requestPasswordReset(_mobileController.text.trim());
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _step = _Step.confirmReset;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = e.message;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _submitConfirm() async {
    if (!_confirmFormKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.confirmPasswordReset(
        mobileNumber: _mobileController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = e.message;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      backgroundColor: context.hh.surfacePage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          child: _step == _Step.requestCode ? _buildRequestStep(context) : _buildConfirmStep(context),
        ),
      ),
    );
  }

  Widget _buildRequestStep(BuildContext context) {
    return Form(
      key: _requestFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter your mobile number and we will text you a reset code.',
            style: TextStyle(fontSize: HHTypeScale.textMd, color: context.hh.textMuted),
          ),
          const SizedBox(height: HHSpacing.space7),
          if (_errorMessage != null) HHErrorBanner(message: _errorMessage!),
          HHTextField(
            label: 'Mobile number',
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            enabled: !_isBusy,
            prefixIcon: const Icon(Icons.call_outlined),
            prefixText: '+252 ',
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Mobile number is required.' : null,
          ),
          const SizedBox(height: HHSpacing.space7),
          HHGoldButton(label: 'Send reset code', isLoading: _isBusy, onPressed: _submitRequest),
        ],
      ),
    );
  }

  Widget _buildConfirmStep(BuildContext context) {
    return Form(
      key: _confirmFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'We sent a code to ${_mobileController.text.trim()}. Enter it below with your new password.',
            style: TextStyle(fontSize: HHTypeScale.textMd, color: context.hh.textMuted),
          ),
          const SizedBox(height: HHSpacing.space7),
          if (_errorMessage != null) HHErrorBanner(message: _errorMessage!),
          HHTextField(
            label: 'Reset code',
            controller: _codeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            enabled: !_isBusy,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Enter the 6-digit code.';
              return null;
            },
          ),
          const SizedBox(height: HHSpacing.space5),
          HHTextField(
            label: 'New password',
            controller: _newPasswordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            enabled: !_isBusy,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required.';
              if (value.length < 8) return 'Password must be at least 8 characters.';
              return null;
            },
          ),
          const SizedBox(height: HHSpacing.space7),
          HHGoldButton(label: 'Confirm reset', isLoading: _isBusy, onPressed: _submitConfirm),
          const SizedBox(height: HHSpacing.space4),
          TextButton(
            onPressed: _isBusy
                ? null
                : () => setState(() {
                    _step = _Step.requestCode;
                    _errorMessage = null;
                  }),
            child: const Text('Use a different number'),
          ),
        ],
      ),
    );
  }
}
