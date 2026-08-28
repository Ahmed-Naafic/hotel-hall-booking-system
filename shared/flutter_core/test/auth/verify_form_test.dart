import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('rejects a code that is not 6 digits', (tester) async {
    await tester.pumpWidget(wrap(VerifyForm(
      isBusy: false,
      isResending: false,
      onSubmit: (code) async => true,
      onResend: () async => true,
    )));

    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Verify'));
    await tester.pump();

    expect(find.text('Enter the 6-digit code.'), findsOneWidget);
  });

  testWidgets('calls onSubmit with a valid 6-digit code', (tester) async {
    String? captured;
    await tester.pumpWidget(wrap(VerifyForm(
      isBusy: false,
      isResending: false,
      onSubmit: (code) async {
        captured = code;
        return true;
      },
      onResend: () async => true,
    )));

    await tester.enterText(find.byType(TextFormField), '482913');
    await tester.tap(find.text('Verify'));
    await tester.pump();

    expect(captured, '482913');
  });

  testWidgets('resend button calls onResend', (tester) async {
    var resent = false;
    await tester.pumpWidget(wrap(VerifyForm(
      isBusy: false,
      isResending: false,
      onSubmit: (code) async => true,
      onResend: () async {
        resent = true;
        return true;
      },
    )));

    await tester.tap(find.text("Didn't get a code? Resend"));
    await tester.pump();

    expect(resent, true);
  });

  testWidgets('disables resend and shows sending state while resending', (tester) async {
    await tester.pumpWidget(wrap(VerifyForm(
      isBusy: false,
      isResending: true,
      onSubmit: (code) async => true,
      onResend: () async => true,
    )));

    expect(find.text('Sending…'), findsOneWidget);
  });
}
