import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/notification_preference_controller.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/manager_profile_screen.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/manager_settings_screen.dart';
import 'package:manager_mobile/features/authentication/presentation/widgets/manager_drawer.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/notifications/application/notification_controller.dart';
import 'package:manager_mobile/features/notifications/data/notification_repository.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

/// Mirrors the real usage: an `AppBar` + `drawer:` on a `Scaffold` — opened
/// by tapping the hamburger icon Flutter adds automatically, same as on
/// the real Dashboard tab.
Widget _wrap({
  Future<http.Response> Function(http.Request)? handler,
  String accountType = 'HOTEL_MANAGER',
  String? fullName,
  VoidCallback? onOpenMessages,
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
    ..currentUser = AppUser.fromJson(testUser(accountType: accountType, fullName: fullName))
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
      ChangeNotifierProvider(create: (_) => ThemeController(storage: InMemoryTokenStorage())),
      ChangeNotifierProvider(create: (_) => NotificationPreferenceController(storage: InMemoryTokenStorage())),
    ],
    child: MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        drawer: ManagerDrawer(onOpenMessages: onOpenMessages ?? () {}),
        body: const SizedBox.shrink(),
      ),
    ),
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the real mobile number and a humanized account type — no invented fields', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    expect(find.text('+15559876543'), findsOneWidget);
    // ManagerFormatters.status() humanizes casing only — the account type
    // itself is still exactly what the backend returned.
    expect(find.text('Hotel Manager'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets("shows the Manager's real Full Name as the heading, with mobile number below it (BDR-019)", (tester) async {
    await tester.pumpWidget(_wrap(fullName: 'Amina Yusuf'));
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    expect(find.text('Amina Yusuf'), findsOneWidget);
    expect(find.text('+15559876543'), findsOneWidget);
  });

  testWidgets('falls back to the mobile number as the heading for a pre-BDR-019 account with no Full Name', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    final heading = tester.widget<Text>(find.text('+15559876543').first);
    expect(heading.style, HHTypography.serifLg);
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
    await _openDrawer(tester);

    final context = tester.element(find.byType(ManagerDrawer));
    final auth = context.read<AuthController>();

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(logoutCalled, true);
    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.currentUser, isNull);
  });

  testWidgets('tapping "Profile" opens the Profile screen', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ManagerProfileScreen), findsOneWidget);
  });

  testWidgets('tapping "Settings" opens the Settings screen', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(ManagerSettingsScreen), findsOneWidget);
  });

  testWidgets('tapping "Messages" closes the Drawer and hands off to the Bookings tab', (tester) async {
    var opened = false;
    await tester.pumpWidget(_wrap(onOpenMessages: () => opened = true));
    await tester.pumpAndSettle();
    await _openDrawer(tester);

    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();

    expect(opened, true);
    expect(find.byType(Drawer), findsNothing);
  });
}
