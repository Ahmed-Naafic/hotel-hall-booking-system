import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/testing.dart';
import 'package:manager_mobile/core/auth_gate.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/home_screen.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/verify_screen.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/notifications/application/notification_controller.dart';
import 'package:manager_mobile/features/notifications/data/notification_repository.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

/// HomeScreen is now a bottom-navigation shell whose tabs (Home, Hotel,
/// Halls) read the same `HotelContextController` main.dart wires up in the
/// real app — this fixture mirrors that wiring so the widget tree AuthGate
/// eventually reaches builds successfully. The Hotel client always answers
/// "no Hotel yet"; these tests only care about the Auth/Verify transition.
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

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '482913');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('resend requests a new code', (tester) async {
    final storage = InMemoryTokenStorage();
    await storage.write('hh_access_token', 'tok');
    final sessionStore = SessionStore(storage: storage);
    var resendCalled = false;
    final client = ApiClient(
      httpClient: MockClient((r) async {
        if (r.url.path.endsWith('/auth/me')) return successResponse(testUser(isVerified: false));
        if (r.url.path.endsWith('/auth/verifications')) {
          resendCalled = true;
          return successResponse({});
        }
        throw StateError('unexpected: ${r.url.path}');
      }),
      baseUrl: 'http://test/api/v1',
      accessTokenProvider: () => sessionStore.accessToken,
    );
    final controller = AuthController(repository: AuthRepository(client), sessionStore: sessionStore);

    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Didn't get a code? Resend"));
    await tester.pumpAndSettle();

    expect(resendCalled, true);
  });
}
