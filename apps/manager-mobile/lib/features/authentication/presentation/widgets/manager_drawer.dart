import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/manager_formatters.dart';
import '../../../../core/push_notification_service.dart';
import '../../../hotel/application/hotel_context_controller.dart';
import '../../../notifications/application/notification_controller.dart';

/// Manager → Account, reached from the hamburger menu on the Home tab
/// (replaces the previous standalone "Profile" bottom-nav destination).
/// Shows only the real, already-available `AppUser` fields — Full Name
/// (BDR-019, `null` only for an account registered before that decision),
/// mobile number, and account type — no field invented, and no account
/// editing (not an approved capability).
class ManagerDrawer extends StatelessWidget {
  const ManagerDrawer({super.key});

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

    return Drawer(
      backgroundColor: context.hh.surfacePage,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HHSpacing.space6,
            vertical: HHSpacing.space5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: HHSpacing.space4),
              CircleAvatar(
                radius: 32,
                backgroundColor: context.hh.surfaceNavyTint,
                child: Icon(Icons.person, size: 36, color: context.hh.textHeading),
              ),
              const SizedBox(height: HHSpacing.space5),
              Text(
                user?.fullName ?? user?.mobileNumber ?? '',
                style: HHTypography.serifLg.copyWith(color: context.hh.textHeading),
              ),
              if (user?.fullName != null) ...[
                const SizedBox(height: HHSpacing.space1),
                Text(
                  user!.mobileNumber,
                  style: TextStyle(color: context.hh.textMuted),
                ),
              ],
              const SizedBox(height: HHSpacing.space1),
              Text(
                ManagerFormatters.status(user?.accountType ?? ''),
                style: TextStyle(color: context.hh.textMuted),
              ),
              const Spacer(),
              const Divider(),
              const SizedBox(height: HHSpacing.space3),
              const HHSectionLabel('APPEARANCE'),
              const SizedBox(height: HHSpacing.space3),
              Consumer<ThemeController>(
                builder: (context, themeController, _) => HHThemeModeToggle(
                  mode: themeController.mode,
                  onChanged: themeController.setMode,
                ),
              ),
              const SizedBox(height: HHSpacing.space3),
              HHSecondaryButton(
                label: 'Log out',
                icon: Icons.logout,
                onPressed: () => _logout(context),
              ),
              const SizedBox(height: HHSpacing.space3),
            ],
          ),
        ),
      ),
    );
  }
}
