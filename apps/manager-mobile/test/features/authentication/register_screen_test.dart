import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/auth_gate.dart';
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

void main() {
  testWidgets('successful registration sends accountType HOTEL_MANAGER (BR-AUTH-03)', (tester) async {
    final calls = <Map<String, dynamic>>[];
    final controller = _controller(handler: (r) async {
      calls.add({'path': r.url.path, 'body': r.body});
      if (r.url.path.endsWith('/auth/register')) return successResponse(testUser(isVerified: false), status: 201);
      if (r.url.path.endsWith('/auth/login')) {
        return successResponse({'accessToken': 'a', 'refreshToken': 'b', 'user': testUser(isVerified: false)});
      }
      if (r.url.path.endsWith('/auth/verifications')) return successResponse({});
      throw StateError('unexpected: ${r.url.path}');
    });

    await tester.pumpWidget(ChangeNotifierProvider<AuthController>.value(
      value: controller,
      child: const MaterialApp(home: RegisterScreen()),
    ));

    await tester.enterText(find.byType(TextFormField).at(0), '+15559876543');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    final registerCall = calls.firstWhere((c) => (c['path'] as String).endsWith('/auth/register'));
    expect(registerCall['body'], contains('"accountType":"HOTEL_MANAGER"'));
    expect(controller.status, AuthStatus.authenticated);
  });

  testWidgets('an already-registered mobile number shows the server error message', (tester) async {
    final controller = _controller(
      handler: (r) async => errorResponse('BUSINESS_RULE_ERROR', 'The mobile number is already registered.', 422),
    );

    await tester.pumpWidget(ChangeNotifierProvider<AuthController>.value(
      value: controller,
      child: const MaterialApp(home: RegisterScreen()),
    ));

    await tester.enterText(find.byType(TextFormField).at(0), '+15559876543');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('The mobile number is already registered.'), findsOneWidget);
  });

  testWidgets('navigating from Login to Register and back reaches LoginScreen again via AuthGate', (tester) async {
    final controller = _controller();
    await tester.pumpWidget(ChangeNotifierProvider<AuthController>.value(
      value: controller,
      child: const MaterialApp(home: AuthGate()),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text("Don't have a Hotel account? Register"));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
