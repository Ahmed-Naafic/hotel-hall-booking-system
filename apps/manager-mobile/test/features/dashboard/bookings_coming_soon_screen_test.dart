import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_mobile/features/dashboard/presentation/screens/bookings_coming_soon_screen.dart';

void main() {
  testWidgets('shows the empty Hotel setup state when no Hotel is available', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BookingsComingSoonScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Set up your Hotel'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });
}
