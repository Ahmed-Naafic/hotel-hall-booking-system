import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/auth_gate.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/home_screen.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/verify_screen.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/notifications/application/notification_controller.dart';
import 'package:manager_mobile/features/notifications/data/notification_repository.dart';
import 'package:provider/provider.dart';

import '../test_support.dart';

/// HomeScreen is now a bottom-navigation shell whose tabs (Home, Hotel,
/// Halls) read the same `HotelContextController` main.dart wires up in the
/// real app — this fixture mirrors that wiring so the widget tree AuthGate
/// eventually reaches builds successfully. The Hotel client always answers
/// "no Hotel yet"; no test here cares about Hotel content, only that
/// AuthGate itself resolves to the right top-level screen.
Widget _wrap(AuthController controller) {
  final hotelClient = ApiClient(
    httpClient: MockClient((r) async => successResponse({'hotel': null, 'latestApplication': null})),
    baseUrl: 'http://test/api/v1',
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: controller),
      Provider<ApiClient>.value(value: hotelClient),
      ChangeNotifierProvider<HotelContextController>(
        create: (_) => HotelContextController(
          repository: HotelRepository(hotelClient),
          storage: InMemoryTokenStorage(),
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => NotificationController(NotificationRepository(hotelClient)),
      ),
    ],
    child: const MaterialApp(home: AuthGate()),
  );
}

AuthController _controllerWith(TokenStorage storage, {Future<http.Response> Function(http.Request)? handler}) {
  final sessionStore = SessionStore(storage: storage);
  final client = ApiClient(
    httpClient: MockClient(handler ?? (r) async => successResponse(testUser())),
    baseUrl: 'http://test/api/v1',
    accessTokenProvider: () => sessionStore.accessToken,
  );
  return AuthController(repository: AuthRepository(client), sessionStore: sessionStore);
}

void main() {
  testWidgets('shows a loading indicator, then LoginScreen, when no session is stored', (tester) async {
    final controller = _controllerWith(InMemoryTokenStorage());

    await tester.pumpWidget(_wrap(controller));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a Hotel Manager may log in and reach HomeScreen regardless of Hotel approval state (BR-AUTH-04)', (tester) async {
    final storage = InMemoryTokenStorage();
    await storage.write('hh_access_token', 'tok');
    final controller = _controllerWith(storage, handler: (r) async => successResponse(testUser(isVerified: true)));

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('shows VerifyScreen when a valid but unverified session is restored', (tester) async {
    final storage = InMemoryTokenStorage();
    await storage.write('hh_access_token', 'tok');
    final controller = _controllerWith(storage, handler: (r) async => successResponse(testUser(isVerified: false)));

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.byType(VerifyScreen), findsOneWidget);
  });

  testWidgets('falls back to LoginScreen when a stored session is invalid/expired (BR-AUTH-11)', (tester) async {
    final storage = InMemoryTokenStorage();
    await storage.write('hh_access_token', 'stale');
    final controller = _controllerWith(storage, handler: (r) async => errorResponse('AUTHENTICATION_ERROR', 'Invalid or expired session.', 401));

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
