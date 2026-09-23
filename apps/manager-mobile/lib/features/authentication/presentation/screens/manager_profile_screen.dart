import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/manager_formatters.dart';

/// Manager → Profile, reached from the Drawer. Shows only the real,
/// already-available `AppUser` fields — Full Name (BDR-019, `null` only for
/// an account registered before that decision), mobile number, and account
/// type — no field invented, and no account editing (not an approved
/// capability, matching `ManagerDrawer`'s own original doc comment this
/// screen now carries forward).
class ManagerProfileScreen extends StatelessWidget {
  const ManagerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: context.hh.surfaceNavyTint,
                  child: Icon(Icons.person, size: 36, color: context.hh.textHeading),
                ),
                const SizedBox(width: HHSpacing.space5),
                Expanded(
                  child: Text(
                    user?.fullName ?? user?.mobileNumber ?? '',
                    style: HHTypography.serifLg.copyWith(color: context.hh.textHeading),
                  ),
                ),
              ],
            ),
            const SizedBox(height: HHSpacing.space6),
            HHCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HHSectionLabel('ACCOUNT'),
                  _row(context, 'Mobile number', user?.mobileNumber ?? ''),
                  _row(context, 'Account type', ManagerFormatters.status(user?.accountType ?? '')),
                  _row(context, 'Verification', user?.isVerified == true ? 'Verified' : 'Not verified'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: HHSpacing.space2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.hh.textMuted)),
        Text(value, style: TextStyle(fontWeight: HHTypeScale.weightSemibold)),
      ],
    ),
  );
}
