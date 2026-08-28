import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows validation errors and never calls onSubmit for empty fields', (tester) async {
    var submitted = false;
    await tester.pumpWidget(wrap(RegisterForm(
      isBusy: false,
      onSubmit: ({required mobileNumber, required password}) async {
        submitted = true;
        return true;
      },
    )));

    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Mobile number is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(submitted, false);
  });

  testWidgets('rejects a password shorter than 8 characters', (tester) async {
    await tester.pumpWidget(wrap(RegisterForm(
      isBusy: false,
      onSubmit: ({required mobileNumber, required password}) async => true,
    )));

    await tester.enterText(find.byType(TextFormField).at(0), '+15551234567');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters.'), findsOneWidget);
  });

  testWidgets('calls onSubmit with trimmed valid input', (tester) async {
    String? capturedMobile;
    String? capturedPassword;
    await tester.pumpWidget(wrap(RegisterForm(
      isBusy: false,
      onSubmit: ({required mobileNumber, required password}) async {
        capturedMobile = mobileNumber;
        capturedPassword = password;
        return true;
      },
    )));

    await tester.enterText(find.byType(TextFormField).at(0), ' +15551234567 ');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(capturedMobile, '+15551234567');
    expect(capturedPassword, 'password123');
  });

  testWidgets('shows a loading spinner and disables the button while busy', (tester) async {
    await tester.pumpWidget(wrap(RegisterForm(
      isBusy: true,
      onSubmit: ({required mobileNumber, required password}) async => true,
    )));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('displays the server error message when present', (tester) async {
    await tester.pumpWidget(wrap(RegisterForm(
      isBusy: false,
      errorMessage: 'The mobile number is already registered.',
      onSubmit: ({required mobileNumber, required password}) async => true,
    )));

    expect(find.text('The mobile number is already registered.'), findsOneWidget);
  });
}
