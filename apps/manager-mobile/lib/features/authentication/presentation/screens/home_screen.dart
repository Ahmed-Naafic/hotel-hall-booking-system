import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../hotel/application/hotel_context_controller.dart';
import '../../../hotel/presentation/screens/my_hotel_screen.dart';

/// Manager — the authenticated landing screen. Navigation per the approved
/// nav tree: Manager → My Hotel → Halls → Hall Details → Create/Edit Hall.
/// A visual entry point only — this screen has exactly one real
/// destination (My Hotel) because that is the only module actually
/// implemented; no Dashboard metrics, Bookings, or Calendar exist to link
/// to yet.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthController>();
    final hotelContext = context.read<HotelContextController>();
    await auth.logout();
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
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HHSpacing.space7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: HHTypography.displaySm),
              const SizedBox(height: HHSpacing.space2),
              Text(
                user?.mobileNumber ?? '',
                style: TextStyle(
                  fontSize: HHTypeScale.textMd,
                  color: HHColors.textMuted,
                ),
              ),
              const SizedBox(height: HHSpacing.space8),
              HHCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyHotelScreen()),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: HHColors.surfaceNavyTint,
                        borderRadius: BorderRadius.circular(HHRadii.control),
                      ),
                      child: Icon(
                        Icons.apartment_rounded,
                        color: HHColors.actionPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: HHSpacing.space5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Hotel',
                            style: TextStyle(
                              fontWeight: HHTypeScale.weightSemibold,
                              fontSize: HHTypeScale.textLg,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage your Hotel and its Halls',
                            style: TextStyle(
                              color: HHColors.textMuted,
                              fontSize: HHTypeScale.textSm,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: HHColors.textSubtle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
