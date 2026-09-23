import 'package:customer_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:customer_mobile/features/authentication/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

AuthController _controller({
  Future<http.Response> Function(http.Request)? handler,
}) {
  final sessionStore = SessionStore(storage: InMemoryTokenStorage());
  final client = ApiClient(
    httpClient: MockClient(handler ?? (r) async => successResponse(testUser())),
    baseUrl: 'http://test/api/v1',
    accessTokenProvider: () => sessionStore.accessToken,
  );
  return AuthController(
    repository: AuthRepository(client),
    sessionStore: sessionStore,
  );
}

Widget _wrap(AuthController controller, Widget child) =>
    ChangeNotifierProvider<AuthController>.value(
      value: controller,
      child: MaterialApp(home: child),
    );

/// The redesigned Login screen (hero panel + card + feature icons + footer)
/// is taller than the default test viewport — every tap target below the
/// fold needs scrolling into view first, unlike a plain `tester.tap`.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  testWidgets(
    'a successful login leaves the AuthController authenticated',
    (tester) async {
      final controller = _controller(
        handler: (r) async {
          if (r.url.path.endsWith('/auth/login')) {
            return successResponse({
              'accessToken': 'a',
              'refreshToken': 'b',
              'user': testUser(),
            });
          }
          throw StateError('unexpected: ${r.url.path}');
        },
      );

      await tester.pumpWidget(_wrap(controller, const LoginScreen()));
      await tester.enterText(find.byType(TextFormField).at(0), '+15551234567');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await _tap(tester, find.text('Log in'));
      await tester.pumpAndSettle();

      expect(controller.status, AuthStatus.authenticated);
    },
  );

  testWidgets(
    'invalid credentials shows the server error message, stays on LoginScreen',
    (tester) async {
      final controller = _controller(
        handler: (r) async =>
            errorResponse('AUTHENTICATION_ERROR', 'Invalid credentials.', 401),
      );

      await tester.pumpWidget(_wrap(controller, const LoginScreen()));
      await tester.enterText(find.byType(TextFormField).at(0), '+15551234567');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
      await _tap(tester, find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets('tapping "Register" navigates to RegisterScreen', (tester) async {
    final controller = _controller();
    await tester.pumpWidget(_wrap(controller, const LoginScreen()));

    await _tap(tester, find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('tapping "Forgot password?" navigates to ForgotPasswordScreen', (tester) async {
    final controller = _controller();
    await tester.pumpWidget(_wrap(controller, const LoginScreen()));

    await _tap(tester, find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  });

  testWidgets('the dark theme reaches the login CTA as the design\'s own gold gradient', (tester) async {
    // End-to-end through the real screen rather than the form in isolation:
    // this is what proves the palette change actually lands on the painted
    // button, and not just in the token file.
    final controller = _controller();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: controller,
        child: MaterialApp(
          theme: buildHotelHallTheme(brightness: Brightness.dark),
          home: const LoginScreen(),
        ),
      ),
    );

    final ink = tester.widget<Ink>(
      find.descendant(of: find.byType(HHGoldButton), matching: find.byType(Ink)),
    );
    final gradient = (ink.decoration as BoxDecoration).gradient as LinearGradient;
    expect(gradient.colors, [const Color(0xFFEFC762), const Color(0xFFB17E32)]);

    final hero = tester.widget<Container>(
      find.descendant(of: find.byType(AuthHeroHeader), matching: find.byType(Container)).first,
    );
    final heroGradient = (hero.decoration as BoxDecoration).gradient as LinearGradient;
    expect(
      heroGradient.colors.last.computeLuminance(),
      lessThan(heroGradient.colors.first.computeLuminance()),
      reason: 'the hero is lit at the crown and deepens toward the card',
    );
  });

  testWidgets('a successful login with "Remember me" unchecked never persists the session', (tester) async {
    final storage = InMemoryTokenStorage();
    final sessionStore = SessionStore(storage: storage);
    final client = ApiClient(
      httpClient: MockClient((r) async {
        if (r.url.path.endsWith('/auth/login')) {
          return successResponse({'accessToken': 'a', 'refreshToken': 'b', 'user': testUser()});
        }
        throw StateError('unexpected: ${r.url.path}');
      }),
      baseUrl: 'http://test/api/v1',
      accessTokenProvider: () => sessionStore.accessToken,
    );
    final controller = AuthController(repository: AuthRepository(client), sessionStore: sessionStore);

    await tester.pumpWidget(_wrap(controller, const LoginScreen()));
    await tester.enterText(find.byType(TextFormField).at(0), '+15551234567');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await _tap(tester, find.text('Remember me'));
    await _tap(tester, find.text('Log in'));
    await tester.pumpAndSettle();

    expect(controller.status, AuthStatus.authenticated);
    expect(await storage.read('hh_access_token'), isNull);
  });
}
