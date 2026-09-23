import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows validation errors for empty fields', (tester) async {
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: false,
      onForgotPassword: () {},
      onSubmit: ({required mobileNumber, required password, required rememberMe}) async => true,
    )));

    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(find.text('Mobile number is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('calls onSubmit with entered credentials and the default remember-me choice', (tester) async {
    String? capturedMobile;
    bool? capturedRememberMe;
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: false,
      onForgotPassword: () {},
      onSubmit: ({required mobileNumber, required password, required rememberMe}) async {
        capturedMobile = mobileNumber;
        capturedRememberMe = rememberMe;
        return true;
      },
    )));

    await tester.enterText(find.byType(TextFormField).at(0), '+15551234567');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(capturedMobile, '+15551234567');
    // "Remember me" is checked by default, matching every session's
    // behavior before this feature existed.
    expect(capturedRememberMe, isTrue);
  });

  testWidgets('unchecking "Remember me" passes rememberMe: false to onSubmit', (tester) async {
    bool? capturedRememberMe;
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: false,
      onForgotPassword: () {},
      onSubmit: ({required mobileNumber, required password, required rememberMe}) async {
        capturedRememberMe = rememberMe;
        return true;
      },
    )));

    await tester.enterText(find.byType(TextFormField).at(0), '+15551234567');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Remember me'));
    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(capturedRememberMe, isFalse);
  });

  testWidgets('the password visibility toggle switches obscureText', (tester) async {
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: false,
      onForgotPassword: () {},
      onSubmit: ({required mobileNumber, required password, required rememberMe}) async => true,
    )));

    bool obscured() => tester.widget<EditableText>(find.byType(EditableText).at(1)).obscureText;

    expect(obscured(), isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    expect(obscured(), isFalse);
  });

  testWidgets('tapping "Forgot password?" calls onForgotPassword', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: false,
      onForgotPassword: () => tapped = true,
      onSubmit: ({required mobileNumber, required password, required rememberMe}) async => true,
    )));

    await tester.tap(find.text('Forgot password?'));
    expect(tapped, isTrue);
  });

  testWidgets('shows the distinct inactive-account error message (BR-AUTH-06)', (tester) async {
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: false,
      errorMessage: 'This account is inactive.',
      onForgotPassword: () {},
      onSubmit: ({required mobileNumber, required password, required rememberMe}) async => true,
    )));

    expect(find.text('This account is inactive.'), findsOneWidget);
  });

  testWidgets('disables the submit button while busy', (tester) async {
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: true,
      onForgotPassword: () {},
      onSubmit: ({required mobileNumber, required password, required rememberMe}) async => true,
    )));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('signs in with the gold call-to-action, not the navy one', (tester) async {
    // In dark mode navy is the ground the card is painted on, so a navy
    // primary button on these screens is a shape you have to hunt for.
    // Gold is the only brand colour that carries on both grounds.
    await tester.pumpWidget(wrap(LoginForm(
      isBusy: false,
      onForgotPassword: () {},
      onSubmit: ({required mobileNumber, required password, required rememberMe}) async => true,
    )));

    expect(find.byType(HHGoldButton), findsOneWidget);
    expect(find.byType(HHPrimaryButton), findsNothing);
  });
}
