import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_mobile/main.dart';

void main() {
  testWidgets('ManagerMobileApp builds and shows the auth loading state first', (WidgetTester tester) async {
    await tester.pumpWidget(const ManagerMobileApp());

    // Before session restoration resolves, AuthGate shows a loading
    // indicator — the real placeholder-free entry point now that FE-06 is
    // implemented (superseding the scaffold-era "Hotel Manager Mobile" text
    // this test originally checked for).
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
