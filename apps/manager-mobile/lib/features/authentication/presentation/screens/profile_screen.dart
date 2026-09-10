import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/manager_formatters.dart';
import '../../../../core/push_notification_service.dart';
import '../../../hotel/application/hotel_context_controller.dart';
import '../../../notifications/application/notification_controller.dart';

/// Manager → Account — a standalone pushed screen (never a bottom-nav tab;
/// this app has no bottom navigation, `folder-structure.md`'s approved nav
/// tree stays a plain push stack). Shows only the real, already-available
/// `AppUser` fields — Full Name (BDR-019, `null` only for an account
/// registered before that decision), mobile number, and account type — no
/// field invented, and no account editing (not an approved capability).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthController>();
    final hotelContext = context.read<HotelContextController>();
    // Best-effort — unregister this device's push token before the session
    // that authorized it goes away, so a shared device never keeps
    // receiving this account's notifications after logging out.
    final token = await PushNotificationService.instance.getToken();
    if (context.mounted) {
      await context.read<NotificationController>().unregisterDeviceToken(token);
    }
    await auth.logout();
    await hotelContext.clearOnLogout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          children: [
            const SizedBox(height: HHSpacing.space5),
            CircleAvatar(
              radius: 38,
              backgroundColor: HHColors.navy100,
              child: Icon(Icons.person, size: 42, color: HHColors.navy700),
            ),
            const SizedBox(height: HHSpacing.space5),
            Text(
              user?.fullName ?? user?.mobileNumber ?? '',
              textAlign: TextAlign.center,
              style: HHTypography.serifLg,
            ),
            if (user?.fullName != null) ...[
              const SizedBox(height: HHSpacing.space2),
              Text(
                user!.mobileNumber,
                textAlign: TextAlign.center,
                style: TextStyle(color: HHColors.textMuted),
              ),
            ],
            const SizedBox(height: HHSpacing.space2),
            Text(
              ManagerFormatters.status(user?.accountType ?? ''),
              textAlign: TextAlign.center,
              style: TextStyle(color: HHColors.textMuted),
            ),
            const SizedBox(height: HHSpacing.space8),
            HHSecondaryButton(
              label: 'Log out',
              icon: Icons.logout,
              onPressed: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
