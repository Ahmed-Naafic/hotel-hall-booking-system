import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows validation errors for empty fields', (tester) async {
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: false,
      onSubmit: ({required mobileNumber, required password}) async => true,
    )));

    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(find.text('Mobile number is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('calls onSubmit with entered credentials', (tester) async {
    String? capturedMobile;
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: false,
      onSubmit: ({required mobileNumber, required password}) async {
        capturedMobile = mobileNumber;
        return true;
      },
    )));

    await tester.enterText(find.byType(TextFormField).at(0), '+15551234567');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(capturedMobile, '+15551234567');
  });

  testWidgets('shows the distinct inactive-account error message (BR-AUTH-06)', (tester) async {
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: false,
      errorMessage: 'This account is inactive.',
      onSubmit: ({required mobileNumber, required password}) async => true,
    )));

    expect(find.text('This account is inactive.'), findsOneWidget);
  });

  testWidgets('disables the submit button while busy', (tester) async {
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: true,
      onSubmit: ({required mobileNumber, required password}) async => true,
    )));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
