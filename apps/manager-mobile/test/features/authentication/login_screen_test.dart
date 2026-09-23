import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/register_screen.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

AuthController _controller({Future<http.Response> Function(http.Request)? handler}) {
  final sessionStore = SessionStore(storage: InMemoryTokenStorage());
  final client = ApiClient(
    httpClient: MockClient(handler ?? (r) async => successResponse(testUser())),
    baseUrl: 'http://test/api/v1',
    accessTokenProvider: () => sessionStore.accessToken,
  );
  return AuthController(repository: AuthRepository(client), sessionStore: sessionStore);
}

Widget _wrap(AuthController controller, Widget child) => ChangeNotifierProvider<AuthController>.value(
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
  testWidgets('successful login reaches an authenticated AuthController state', (tester) async {
    final controller = _controller(
      handler: (r) async {
        if (r.url.path.endsWith('/auth/login')) {
          return successResponse({'accessToken': 'a', 'refreshToken': 'b', 'user': testUser()});
        }
        throw StateError('unexpected: ${r.url.path}');
      },
    );

    await tester.pumpWidget(_wrap(controller, const LoginScreen()));
    await tester.enterText(find.byType(TextFormField).at(0), '+15559876543');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await _tap(tester, find.text('Log in'));
    await tester.pumpAndSettle();

    expect(controller.status, AuthStatus.authenticated);
  });

  testWidgets('a deactivated Hotel Manager account shows the distinct inactive message (BR-AUTH-06)', (tester) async {
    final controller = _controller(handler: (r) async => errorResponse('AUTHENTICATION_ERROR', 'This account is inactive.', 401));

    await tester.pumpWidget(_wrap(controller, const LoginScreen()));
    await tester.enterText(find.byType(TextFormField).at(0), '+15559876543');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await _tap(tester, find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('This account is inactive.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

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
    await tester.enterText(find.byType(TextFormField).at(0), '+15559876543');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await _tap(tester, find.text('Remember me'));
    await _tap(tester, find.text('Log in'));
    await tester.pumpAndSettle();

    expect(controller.status, AuthStatus.authenticated);
    expect(await storage.read('hh_access_token'), isNull);
  });
}
