import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_mobile/features/dashboard/presentation/screens/bookings_coming_soon_screen.dart';

void main() {
  testWidgets('shows an acknowledgement only — never fake bookings data', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BookingsComingSoonScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Bookings'), findsWidgets);
    expect(find.text('Booking management is coming soon.'), findsOneWidget);
    // No list, no stats, no invented booking rows.
    expect(find.byType(ListView), findsNothing);
  });
}
