import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows validation errors and never calls onSubmit for empty fields', (tester) async {
    var submitted = false;
    await tester.pumpWidget(wrap(RegisterForm(
      isBusy: false,
      onSubmit: ({required mobileNumber, required password, fullName}) async {
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
      onSubmit: ({required mobileNumber, required password, fullName}) async => true,
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
      onSubmit: ({required mobileNumber, required password, fullName}) async {
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
      onSubmit: ({required mobileNumber, required password, fullName}) async => true,
    )));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('displays the server error message when present', (tester) async {
    await tester.pumpWidget(wrap(RegisterForm(
      isBusy: false,
      errorMessage: 'The mobile number is already registered.',
      onSubmit: ({required mobileNumber, required password, fullName}) async => true,
    )));

    expect(find.text('The mobile number is already registered.'), findsOneWidget);
  });

  group('requireFullName (BDR-018)', () {
    testWidgets('does not show a Full name field by default', (tester) async {
      await tester.pumpWidget(wrap(RegisterForm(
        isBusy: false,
        onSubmit: ({required mobileNumber, required password, fullName}) async => true,
      )));

      expect(find.text('Full name'), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('shows a Full name field first and rejects empty submission', (tester) async {
      var submitted = false;
      await tester.pumpWidget(wrap(RegisterForm(
        isBusy: false,
        requireFullName: true,
        onSubmit: ({required mobileNumber, required password, fullName}) async {
          submitted = true;
          return true;
        },
      )));

      expect(find.text('Full name'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));

      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Full name is required.'), findsOneWidget);
      expect(submitted, false);
    });

    testWidgets('calls onSubmit with the trimmed Full name', (tester) async {
      String? capturedFullName;
      await tester.pumpWidget(wrap(RegisterForm(
        isBusy: false,
        requireFullName: true,
        onSubmit: ({required mobileNumber, required password, fullName}) async {
          capturedFullName = fullName;
          return true;
        },
      )));

      await tester.enterText(find.byType(TextFormField).at(0), ' Amina Yusuf ');
      await tester.enterText(find.byType(TextFormField).at(1), '+15551234567');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(capturedFullName, 'Amina Yusuf');
    });
  });
}
