import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/manager_formatters.dart';
import '../../../../core/push_notification_service.dart';
import '../../../hotel/application/hotel_context_controller.dart';
import '../../../notifications/application/notification_controller.dart';
import '../screens/manager_profile_screen.dart';
import '../screens/manager_settings_screen.dart';

/// Manager → the hamburger-menu Drawer, reached from Home's app bar. A
/// header (real, already-available `AppUser` fields only — no field
/// invented) followed by a plain navigation list: Profile, Settings,
/// Messages, then Log out. Each item either pushes its own screen or (for
/// Messages, which has no standalone inbox screen — Communication V1 is
/// strictly per-Booking) hands off to the Bookings tab via [onOpenMessages],
/// the same pushable-vs-tab distinction `DashboardScreen`'s own
/// `_ChatBadgeAction`/`_NotificationBellAction` already establish.
class ManagerDrawer extends StatelessWidget {
  const ManagerDrawer({super.key, required this.onOpenMessages});

  final VoidCallback onOpenMessages;

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

  void _openMessages(BuildContext context) {
    Navigator.of(context).pop();
    onOpenMessages();
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Drawer(
      backgroundColor: context.hh.surfacePage,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HHSpacing.space6,
                HHSpacing.space5,
                HHSpacing.space6,
                HHSpacing.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
            const Divider(height: 1),
            _MenuItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => _push(context, const ManagerProfileScreen()),
            ),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => _push(context, const ManagerSettingsScreen()),
            ),
            _MenuItem(
              icon: Icons.chat_bubble_outline,
              label: 'Messages',
              onTap: () => _openMessages(context),
            ),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(HHSpacing.space4),
              child: HHSecondaryButton(
                label: 'Log out',
                icon: Icons.logout,
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.hh.textHeading),
      title: Text(label, style: TextStyle(color: context.hh.textHeading)),
      trailing: Icon(Icons.chevron_right, color: context.hh.textSubtle),
      onTap: onTap,
    );
  }
}
