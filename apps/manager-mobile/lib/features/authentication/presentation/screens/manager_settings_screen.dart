import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/notification_preference_controller.dart';
import '../../../../core/push_notification_service.dart';
import '../../../notifications/application/notification_controller.dart';

/// Manager → Settings, reached from the Drawer. Two per-device preferences,
/// neither a server-side Notification V1 concept: Appearance (light/dark/
/// system, `ThemeController`) and whether this device receives push
/// notifications at all (`NotificationPreferenceController`). Toggling the
/// latter actually registers/unregisters this device's token immediately —
/// the preference alone would otherwise silently disagree with reality
/// until the next app restart.
class ManagerSettingsScreen extends StatefulWidget {
  const ManagerSettingsScreen({super.key});

  @override
  State<ManagerSettingsScreen> createState() => _ManagerSettingsScreenState();
}

class _ManagerSettingsScreenState extends State<ManagerSettingsScreen> {
  bool _busy = false;

  Future<void> _setPushEnabled(bool enabled) async {
    setState(() => _busy = true);
    final preference = context.read<NotificationPreferenceController>();
    final notifications = context.read<NotificationController>();
    final token = await PushNotificationService.instance.getToken();
    if (enabled) {
      await notifications.registerDeviceToken(token);
    } else {
      await notifications.unregisterDeviceToken(token);
    }
    await preference.setEnabled(enabled);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          children: [
            const HHSectionLabel('APPEARANCE'),
            const SizedBox(height: HHSpacing.space3),
            Consumer<ThemeController>(
              builder: (context, themeController, _) => HHThemeModeToggle(
                mode: themeController.mode,
                onChanged: themeController.setMode,
              ),
            ),
            const SizedBox(height: HHSpacing.space7),
            const HHSectionLabel('NOTIFICATIONS'),
            const SizedBox(height: HHSpacing.space3),
            HHCard(
              child: Consumer<NotificationPreferenceController>(
                builder: (context, preference, _) => Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Push notifications', style: TextStyle(fontWeight: HHTypeScale.weightSemibold)),
                          const SizedBox(height: HHSpacing.space1),
                          Text(
                            'Get notified about bookings, payments, and messages on this device.',
                            style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textSm),
                          ),
                        ],
                      ),
                    ),
                    _busy
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Switch(value: preference.enabled, onChanged: _setPushEnabled),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
