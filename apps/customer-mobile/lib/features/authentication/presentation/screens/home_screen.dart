import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

/// C8 — the authenticated landing screen. Hall browsing/search (BR-HALL-08)
/// is a separate, not-yet-scoped feature — this screen is the minimal,
/// honest post-login destination C4/C5 require, not an invented feature.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(
        title: const Text('Hotel Hall'),
        actions: [IconButton(onPressed: auth.logout, icon: const Icon(Icons.logout), tooltip: 'Log out')],
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
            ],
          ),
        ),
      ),
    );
  }
}
