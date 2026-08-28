import 'package:customer_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:customer_mobile/features/authentication/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

void main() {
  testWidgets('successful login navigates to HomeScreen via AuthController state', (tester) async {
    final controller = _controller(
      handler: (r) async {
        if (r.url.path.endsWith('/auth/login')) {
          return successResponse({'accessToken': 'a', 'refreshToken': 'b', 'user': testUser()});
        }
        throw StateError('unexpected: ${r.url.path}');
      },
    );

    await tester.pumpWidget(_wrap(controller, const LoginScreen()));
    await tester.enterText(find.byType(TextFormField).at(0), '+15551234567');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(controller.status, AuthStatus.authenticated);
  });

  testWidgets('invalid credentials shows the server error message, stays on LoginScreen', (tester) async {
    final controller = _controller(
      handler: (r) async => errorResponse('AUTHENTICATION_ERROR', 'Invalid credentials.', 401),
    );

    await tester.pumpWidget(_wrap(controller, const LoginScreen()));
    await tester.enterText(find.byType(TextFormField).at(0), '+15551234567');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('tapping "Register" navigates to RegisterScreen', (tester) async {
    final controller = _controller();
    await tester.pumpWidget(_wrap(controller, const LoginScreen()));

    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}
