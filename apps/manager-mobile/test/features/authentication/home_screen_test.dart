import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/home_screen.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/profile_screen.dart';
import 'package:manager_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_list_screen.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/hotel/presentation/screens/my_hotel_screen.dart';
import 'package:manager_mobile/features/notifications/application/notification_controller.dart';
import 'package:manager_mobile/features/notifications/data/notification_repository.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

Map<String, dynamic> _hotelJson() => {
      'id': 'h1',
      'registeredByUserId': 'u1',
      'status': 'APPROVED_ACTIVE',
      'profileData': {'name': 'The Grand Hotel'},
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

http.Response _hallPageResponse() => http.Response(
      jsonEncode({
        'status': 'success',
        'message': 'ok',
        'data': [],
        'pagination': {'page': 1, 'limit': 20, 'total': 0, 'hasNext': false, 'hasPrevious': false},
      }),
      200,
    );

Widget _wrap({bool withHotel = true}) {
  final apiClient = ApiClient(
    httpClient: MockClient((r) async {
      if (r.url.path.endsWith('/hotels/me')) {
        return successResponse(withHotel ? {'hotel': _hotelJson(), 'latestApplication': null} : {'hotel': null, 'latestApplication': null});
      }
      if (r.url.path.endsWith('/media')) return successResponse({'logo': null, 'photos': []});
      if (r.url.path.endsWith('/bookings')) return successResponse([]);
      if (r.url.path.contains('/halls')) return _hallPageResponse();
      throw StateError('unexpected: ${r.method} ${r.url.path}');
    }),
    baseUrl: 'http://test/api/v1',
  );
  final authController = AuthController(
    repository: AuthRepository(apiClient),
    sessionStore: SessionStore(storage: InMemoryTokenStorage()),
  );
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider<AuthController>.value(value: authController),
      ChangeNotifierProvider<HotelContextController>(
        create: (_) => HotelContextController(repository: HotelRepository(apiClient), storage: InMemoryTokenStorage()),
      ),
      ChangeNotifierProvider(
        create: (_) => NotificationController(NotificationRepository(apiClient)),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

/// `IndexedStack` keeps every tab's widget tree alive even when it isn't
/// the visible one, so a bare `find.text(...)` can match the same label
/// both in the `NavigationBar` and inside an off-screen tab's own AppBar
/// (e.g. the Halls tab's AppBar title is also "Halls"). Scoping to the
/// `NavigationBar` is what actually disambiguates "tap the tab", both here
/// and in the app itself.
Finder _navLabel(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('shows the Dashboard on the Home tab by default, with all 5 nav destinations', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final label in ['Home', 'Hotel', 'Halls', 'Bookings', 'Profile']) {
      expect(_navLabel(label), findsOneWidget, reason: '"$label" nav destination');
    }
  });

  testWidgets('switching to the Hotel tab shows the existing MyHotelScreen, embedded (no back arrow)', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Hotel'));
    await tester.pumpAndSettle();

    expect(find.byType(MyHotelScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('switching to the Halls tab shows the existing HallListScreen once a Hotel exists', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Halls'));
    await tester.pumpAndSettle();

    expect(find.byType(HallListScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('the Halls tab shows "Set up your Hotel" instead of crashing when no Hotel exists yet', (tester) async {
    await tester.pumpWidget(_wrap(withHotel: false));
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Halls'));
    await tester.pumpAndSettle();

    expect(find.byType(HallListScreen), findsNothing);
    expect(find.text('Set up your Hotel'), findsOneWidget);
  });

  testWidgets('switching to the Bookings tab shows the live empty state', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Bookings'));
    await tester.pumpAndSettle();

    expect(find.text('No bookings yet'), findsOneWidget);
  });

  testWidgets('switching to the Profile tab shows the existing ProfileScreen unchanged', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('switching tabs and back preserves each tab\'s own state (IndexedStack, not a reload)', (tester) async {
    // Two distinct call kinds hit the same `/halls` path: the Halls tab's
    // own full list (`limit=20`, via `HallListController`) and the
    // Dashboard's own cheap count-only refresh (`limit=1`, fired whenever
    // Home is re-selected — see `HomeScreen._openTab`). Only the former
    // must never repeat merely from switching tabs; the latter legitimately
    // fires again every time the Manager returns to Home.
    var hallsListCallCount = 0;
    var hallCountCallCount = 0;
    final apiClient = ApiClient(
      httpClient: MockClient((r) async {
        if (r.url.path.endsWith('/hotels/me')) return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
        if (r.url.path.endsWith('/media')) return successResponse({'logo': null, 'photos': []});
        if (r.url.path.contains('/halls')) {
          if (r.url.queryParameters['limit'] == '1') {
            hallCountCallCount += 1;
          } else {
            hallsListCallCount += 1;
          }
          return _hallPageResponse();
        }
        throw StateError('unexpected: ${r.method} ${r.url.path}');
      }),
      baseUrl: 'http://test/api/v1',
    );
    final authController = AuthController(
      repository: AuthRepository(apiClient),
      sessionStore: SessionStore(storage: InMemoryTokenStorage()),
    );
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<HotelContextController>(
          create: (_) => HotelContextController(repository: HotelRepository(apiClient), storage: InMemoryTokenStorage()),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationController(NotificationRepository(apiClient)),
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Halls'));
    await tester.pumpAndSettle();
    final listCallsAfterFirstVisit = hallsListCallCount;
    expect(listCallsAfterFirstVisit, greaterThan(0));

    await tester.tap(_navLabel('Home'));
    await tester.pumpAndSettle();
    // The Dashboard's own count refresh fires here (expected — this is the
    // fix for the stale-count bug) but must never touch the Halls tab's
    // own full list.
    await tester.tap(_navLabel('Halls'));
    await tester.pumpAndSettle();

    expect(hallsListCallCount, listCallsAfterFirstVisit);
    expect(hallCountCallCount, greaterThan(0));
  });

  testWidgets(
    'reselecting the Bookings tab re-fetches, so a Booking created while it sat idle in the background is never missed',
    (tester) async {
      var bookingsCallCount = 0;
      final apiClient = ApiClient(
        httpClient: MockClient((r) async {
          if (r.url.path.endsWith('/hotels/me')) return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
          if (r.url.path.endsWith('/media')) return successResponse({'logo': null, 'photos': []});
          if (r.url.path.endsWith('/bookings')) {
            bookingsCallCount += 1;
            return successResponse([]);
          }
          if (r.url.path.contains('/halls')) return _hallPageResponse();
          throw StateError('unexpected: ${r.method} ${r.url.path}');
        }),
        baseUrl: 'http://test/api/v1',
      );
      final authController = AuthController(
        repository: AuthRepository(apiClient),
        sessionStore: SessionStore(storage: InMemoryTokenStorage()),
      );
      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider<AuthController>.value(value: authController),
          ChangeNotifierProvider<HotelContextController>(
            create: (_) => HotelContextController(repository: HotelRepository(apiClient), storage: InMemoryTokenStorage()),
          ),
          ChangeNotifierProvider(
            create: (_) => NotificationController(NotificationRepository(apiClient)),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(_navLabel('Bookings'));
      await tester.pumpAndSettle();
      final callsAfterFirstVisit = bookingsCallCount;
      expect(callsAfterFirstVisit, greaterThan(0));

      await tester.tap(_navLabel('Home'));
      await tester.pumpAndSettle();
      await tester.tap(_navLabel('Bookings'));
      await tester.pumpAndSettle();

      expect(bookingsCallCount, greaterThan(callsAfterFirstVisit));
    },
  );
}
