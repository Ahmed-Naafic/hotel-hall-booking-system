import 'package:customer_mobile/core/auth_gate.dart';
import 'package:customer_mobile/features/authentication/presentation/screens/home_screen.dart';
import 'package:customer_mobile/features/authentication/presentation/screens/verify_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

void main() {
  testWidgets('confirming a valid code transitions AuthGate from VerifyScreen to HomeScreen', (tester) async {
    final storage = InMemoryTokenStorage();
    await storage.write('hh_access_token', 'tok');
    final sessionStore = SessionStore(storage: storage);
    final client = ApiClient(
      httpClient: MockClient((r) async {
        if (r.url.path.endsWith('/auth/me')) return successResponse(testUser(isVerified: false));
        if (r.url.path.endsWith('/auth/verifications/confirm')) return successResponse(testUser(isVerified: true));
        throw StateError('unexpected: ${r.url.path}');
      }),
      baseUrl: 'http://test/api/v1',
      accessTokenProvider: () => sessionStore.accessToken,
    );
    final controller = AuthController(repository: AuthRepository(client), sessionStore: sessionStore);

    await tester.pumpWidget(ChangeNotifierProvider<AuthController>.value(
      value: controller,
      child: const MaterialApp(home: AuthGate()),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '482913');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('an incorrect code shows the server error message and stays on VerifyScreen', (tester) async {
    final storage = InMemoryTokenStorage();
    await storage.write('hh_access_token', 'tok');
    final sessionStore = SessionStore(storage: storage);
    final client = ApiClient(
      httpClient: MockClient((r) async {
        if (r.url.path.endsWith('/auth/me')) return successResponse(testUser(isVerified: false));
        if (r.url.path.endsWith('/auth/verifications/confirm')) {
          return errorResponse('BUSINESS_RULE_ERROR', 'Invalid or expired verification request.', 422);
        }
        throw StateError('unexpected: ${r.url.path}');
      }),
      baseUrl: 'http://test/api/v1',
      accessTokenProvider: () => sessionStore.accessToken,
    );
    final controller = AuthController(repository: AuthRepository(client), sessionStore: sessionStore);

    await tester.pumpWidget(ChangeNotifierProvider<AuthController>.value(
      value: controller,
      child: const MaterialApp(home: AuthGate()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid or expired verification request.'), findsOneWidget);
    expect(find.byType(VerifyScreen), findsOneWidget);
  });
}
