import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:customer_mobile/core/pending_action_controller.dart';
import 'package:customer_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:customer_mobile/features/authentication/presentation/screens/verify_screen.dart';
import 'package:customer_mobile/features/availability/presentation/screens/book_hall_screen.dart';
import 'package:customer_mobile/features/discovery/data/discovery_models.dart';
import 'package:customer_mobile/features/discovery/presentation/discover_screen.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

/// Covers `HallDetailScreen._book()`'s auth-gate → destination behavior
/// (Approved Implementation Plan) — the auth-gate logic itself
/// (unauthenticated → LoginScreen, unverified → VerifyScreen) is provably
/// unchanged; only the destination once already authenticated+verified
/// changes, from a placeholder SnackBar to `BookHallScreen`.
final _hall = HallSummary(id: 'hall-1', hotelId: 'h1', profileData: const {'name': 'The Ivory Room'});

Widget _wrap({required AuthController auth, Future<http.Response> Function(http.Request)? apiHandler}) {
  final apiClient = ApiClient(
    httpClient: MockClient(apiHandler ?? (r) async => successResponse({'busyPeriods': []})),
    baseUrl: 'http://test/api/v1',
  );
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider(create: (_) => PendingActionController()),
    ],
    child: MaterialApp(home: HallDetailScreen(hall: _hall)),
  );
}

AuthController _unauthenticatedController() {
  final sessionStore = SessionStore(storage: InMemoryTokenStorage());
  final client = ApiClient(
    httpClient: MockClient((r) async => errorResponse('AUTHENTICATION_ERROR', 'no session', 401)),
    baseUrl: 'http://test/api/v1',
    accessTokenProvider: () => sessionStore.accessToken,
  );
  return AuthController(repository: AuthRepository(client), sessionStore: sessionStore);
}

Future<AuthController> _authenticatedController({required bool isVerified}) async {
  final sessionStore = SessionStore(storage: InMemoryTokenStorage());
  final client = ApiClient(
    httpClient: MockClient(
      (r) async => successResponse({'accessToken': 'a', 'refreshToken': 'b', 'user': testUser(isVerified: isVerified)}),
    ),
    baseUrl: 'http://test/api/v1',
    accessTokenProvider: () => sessionStore.accessToken,
  );
  final controller = AuthController(repository: AuthRepository(client), sessionStore: sessionStore);
  await controller.login(mobileNumber: '+15551234567', password: 'password123');
  return controller;
}

void main() {
  testWidgets('an unauthenticated tap on "Book Hall" opens LoginScreen, not BookHallScreen', (tester) async {
    await tester.pumpWidget(_wrap(auth: _unauthenticatedController()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Book Hall'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(BookHallScreen), findsNothing);
  });

  testWidgets('an unverified tap on "Book Hall" opens VerifyScreen, not BookHallScreen', (tester) async {
    final auth = await _authenticatedController(isVerified: false);
    await tester.pumpWidget(_wrap(auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Book Hall'));
    await tester.pumpAndSettle();

    expect(find.byType(VerifyScreen), findsOneWidget);
    expect(find.byType(BookHallScreen), findsNothing);
  });

  testWidgets(
    'an already-authenticated, verified tap on "Book Hall" opens BookHallScreen directly (never the old placeholder snackbar)',
    (tester) async {
      final auth = await _authenticatedController(isVerified: true);
      await tester.pumpWidget(_wrap(auth: auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Book Hall'));
      await tester.pumpAndSettle();

      expect(find.byType(BookHallScreen), findsOneWidget);
      expect(find.text('Booking will be available in the Booking module.'), findsNothing);
    },
  );
}
