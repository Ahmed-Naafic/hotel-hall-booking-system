import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

/// Manager → Bookings tab. Booking management has no backend API yet —
/// this screen deliberately shows nothing but an acknowledgement, never a
/// fake list, fake stats, or a disabled preview of unimplemented UI.
class BookingsComingSoonScreen extends StatelessWidget {
  const BookingsComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: const Text('Bookings')),
      body: const SafeArea(
        child: HHEmptyState(
          icon: Icons.event_note_outlined,
          title: 'Bookings',
          message: 'Booking management is coming soon.',
        ),
      ),
    );
  }
}
