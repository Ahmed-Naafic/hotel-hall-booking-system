import 'package:customer_mobile/core/auth_gate.dart';
import 'package:customer_mobile/core/pending_action_controller.dart';
import 'package:customer_mobile/features/discovery/application/discovery_controller.dart';
import 'package:customer_mobile/features/discovery/data/discovery_repository.dart';
import 'package:customer_mobile/features/discovery/presentation/discover_screen.dart';
import 'package:customer_mobile/features/favorites/application/favorites_controller.dart';
import 'package:customer_mobile/features/favorites/data/favorites_repository.dart';
import 'package:customer_mobile/features/notifications/application/notification_controller.dart';
import 'package:customer_mobile/features/notifications/data/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import '../test_support.dart';

Widget _wrap(AuthController controller) {
  final discoveryClient = ApiClient(
    httpClient: MockClient((_) async => successResponse([])),
    baseUrl: 'http://test/api/v1',
  );
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: discoveryClient),
      ChangeNotifierProvider<AuthController>.value(value: controller),
      ChangeNotifierProvider(create: (_) => PendingActionController()),
      ChangeNotifierProvider(
        create: (_) =>
            DiscoveryController(DiscoveryRepository(discoveryClient)),
      ),
      ChangeNotifierProvider(
        create: (_) => FavoritesController(FavoritesRepository(discoveryClient)),
      ),
      ChangeNotifierProvider(
        create: (_) => NotificationController(NotificationRepository(discoveryClient)),
      ),
    ],
    child: const MaterialApp(home: AuthGate()),
  );
}

AuthController _controllerWith(
  TokenStorage storage, {
  Future<http.Response> Function(http.Request)? handler,
}) {
  final sessionStore = SessionStore(storage: storage);
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

void main() {
  testWidgets('fresh app opens public discovery instead of Login', (
    tester,
  ) async {
    final controller = _controllerWith(InMemoryTokenStorage());
    await tester.pumpWidget(_wrap(controller));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverScreen), findsOneWidget);
  });

  testWidgets('valid verified session restores into discovery', (tester) async {
    final storage = InMemoryTokenStorage();
    await storage.write('hh_access_token', 'tok');
    final controller = _controllerWith(
      storage,
      handler: (_) async => successResponse(testUser(isVerified: true)),
    );
    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverScreen), findsOneWidget);
    expect(controller.status, AuthStatus.authenticated);
  });

  testWidgets('unverified Customer can still browse discovery', (tester) async {
    final storage = InMemoryTokenStorage();
    await storage.write('hh_access_token', 'tok');
    final controller = _controllerWith(
      storage,
      handler: (_) async => successResponse(testUser(isVerified: false)),
    );
    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverScreen), findsOneWidget);
  });

  testWidgets('invalid stored session falls back to Visitor discovery', (
    tester,
  ) async {
    final storage = InMemoryTokenStorage();
    await storage.write('hh_access_token', 'stale');
    final controller = _controllerWith(
      storage,
      handler: (_) async => errorResponse(
        'AUTHENTICATION_ERROR',
        'Invalid or expired session.',
        401,
      ),
    );
    await tester.pumpWidget(_wrap(controller));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverScreen), findsOneWidget);
    expect(controller.status, AuthStatus.unauthenticated);
  });
}
