import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../hotel/application/hotel_context_controller.dart';
import '../../../hotel/presentation/screens/my_hotel_screen.dart';

/// Manager — the authenticated landing screen. Navigation per the approved
/// nav tree: Manager → My Hotel → Halls → Hall Details → Create/Edit Hall.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthController>();
    final hotelContext = context.read<HotelContextController>();
    await auth.logout();
    // Explicit logout only — never on session-expiry (a different device's
    // token going stale isn't "a different person using this device").
    await hotelContext.clearOnLogout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(
        title: const Text('Hotel Hall — Manager'),
        actions: [IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout), tooltip: 'Log out')],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HHSpacing.space7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: HHTypography.displaySm),
              const SizedBox(height: HHSpacing.space2),
              Text(
                user?.mobileNumber ?? '',
                style: TextStyle(fontSize: HHTypeScale.textMd, color: HHColors.textMuted),
              ),
              const SizedBox(height: HHSpacing.space8),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(HHSpacing.space5),
                  leading: Icon(Icons.apartment, color: HHColors.actionPrimary),
                  title: const Text('My Hotel'),
                  subtitle: const Text('Manage your Hotel and its Halls'),
                  trailing: Icon(Icons.chevron_right, color: HHColors.textSubtle),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyHotelScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
