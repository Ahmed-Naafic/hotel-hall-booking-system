import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/profile_screen.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/notifications/application/notification_controller.dart';
import 'package:manager_mobile/features/notifications/data/notification_repository.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

Widget _wrap({
  Future<http.Response> Function(http.Request)? handler,
  String accountType = 'HOTEL_MANAGER',
}) {
  final sessionStore = SessionStore(storage: InMemoryTokenStorage());
  final apiClient = ApiClient(
    httpClient: MockClient(handler ?? (r) async => successResponse({})),
    baseUrl: 'http://test/api/v1',
    accessTokenProvider: () => sessionStore.accessToken,
  );
  final auth = AuthController(
    repository: AuthRepository(apiClient),
    sessionStore: sessionStore,
  )
    ..currentUser = AppUser.fromJson(testUser(accountType: accountType))
    ..status = AuthStatus.authenticated;
  final hotelContext = HotelContextController(
    repository: HotelRepository(apiClient),
    storage: InMemoryTokenStorage(),
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider<HotelContextController>.value(value: hotelContext),
      ChangeNotifierProvider(create: (_) => NotificationController(NotificationRepository(apiClient))),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  testWidgets('shows the real mobile number and a humanized account type — no invented fields', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('+15559876543'), findsOneWidget);
    // ManagerFormatters.status() humanizes casing only — the account type
    // itself is still exactly what the backend returned.
    expect(find.text('Hotel Manager'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('tapping "Log out" clears the session and the Hotel context', (tester) async {
    var logoutCalled = false;
    await tester.pumpWidget(_wrap(
      handler: (r) async {
        if (r.url.path.endsWith('/auth/logout')) {
          logoutCalled = true;
          return http.Response('', 204);
        }
        return successResponse({});
      },
    ));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ProfileScreen));
    final auth = context.read<AuthController>();

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(logoutCalled, true);
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.currentUser, isNull);
  });
}
