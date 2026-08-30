import 'package:customer_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'CustomerMobileApp builds and shows the auth loading state first',
    (WidgetTester tester) async {
      await tester.pumpWidget(const CustomerMobileApp());

      // Before session restoration resolves, AuthGate shows a loading
      // indicator — the real placeholder-free entry point now that FE-03/FE-04
      // are implemented (superseding the scaffold-era "Customer Mobile" text
      // this test originally checked for).
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );
}
