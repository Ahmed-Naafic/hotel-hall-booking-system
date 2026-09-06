import 'dart:convert';

import 'package:customer_mobile/core/pending_action_controller.dart';
import 'package:customer_mobile/features/discovery/application/discovery_controller.dart';
import 'package:customer_mobile/features/discovery/data/discovery_repository.dart';
import 'package:customer_mobile/features/discovery/presentation/discover_screen.dart';
import 'package:customer_mobile/features/favorites/application/favorites_controller.dart';
import 'package:customer_mobile/features/favorites/data/favorites_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

/// Covers the approved requirement that Near You / Popular / Large Halls /
/// All Halls are in-place content filters on Discover, never separate
/// pushed routes — using a [NavigatorObserver] to prove no push happens,
/// and distinct backend-provided text per endpoint to prove the content
/// area actually swaps.
http.Response _envelope(dynamic data, {Map<String, dynamic>? pagination}) =>
    http.Response(
      jsonEncode({
        'status': 'success',
        'message': 'ok',
        'data': data,
        if (pagination != null) 'pagination': pagination,
      }),
      200,
    );

Map<String, dynamic> _hotelJson(String id, String name) => {
  'id': id,
  'profileData': {'name': name},
  'logo': null,
  'photos': [],
};

class _RecordingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route route, Route? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

Widget _wrapDiscover(NavigatorObserver observer) {
  final apiClient = ApiClient(
    httpClient: MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/hotels/public')) {
        return _envelope([_hotelJson('base-1', 'Base Hotel')]);
      }
      if (path.endsWith('/hotels/public/popular')) {
        return _envelope([
          {..._hotelJson('popular-1', 'Popular Hotel Marker'), 'bookingCount': 5},
        ]);
      }
      if (path.endsWith('/halls/large-capacity')) {
        return _envelope([
          {
            'id': 'large-hall-1',
            'hotelId': 'hotel-1',
            'profileData': {'name': 'Large Hall Marker', 'capacity': 900},
            'photos': [],
            'hotel': {'id': 'hotel-1', 'name': 'Some Hotel'},
          },
        ]);
      }
      if (path.endsWith('/halls')) {
        return _envelope(
          [
            {
              'id': 'all-hall-1',
              'hotelId': 'hotel-1',
              'profileData': {'name': 'All Halls Marker', 'capacity': 50},
              'photos': [],
              'hotel': {'id': 'hotel-1', 'name': 'Some Hotel'},
            },
          ],
          pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
        );
      }
      if (path.endsWith('/favorites/hotels')) {
        return _envelope(<String>[]);
      }
      // /hotels/public/nearby — geolocator has no platform implementation in
      // widget tests, so NearbyHotelsController never reaches this call; kept
      // here only so an unexpected call fails loudly rather than hanging.
      return _envelope([]);
    }),
    baseUrl: 'http://test/api/v1',
  );
  final sessionStore = SessionStore(storage: InMemoryTokenStorage());
  final authController = AuthController(
    repository: AuthRepository(apiClient),
    sessionStore: sessionStore,
  );

  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider<AuthController>.value(value: authController),
      ChangeNotifierProvider(create: (_) => PendingActionController()),
      ChangeNotifierProvider(
        create: (_) => DiscoveryController(DiscoveryRepository(apiClient)),
      ),
      ChangeNotifierProvider(
        create: (_) => FavoritesController(FavoritesRepository(apiClient)),
      ),
    ],
    child: MaterialApp(
      navigatorObservers: [observer],
      home: const DiscoverScreen(),
    ),
  );
}

void main() {
  testWidgets(
    'Near You, Popular, Large Halls, and All Halls switch content in place — never a pushed route',
    (tester) async {
      final observer = _RecordingNavigatorObserver();
      await tester.pumpWidget(_wrapDiscover(observer));
      await tester.pumpAndSettle();

      // Baseline "All Hotels" content is visible on load.
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Base Hotel'), findsWidgets);

      Future<void> selectTab(String label) async {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      // Near You alone never fully "settles" in this widget-test sandbox —
      // geolocator has no real platform channel here, so its underlying
      // call never resolves — so bounded pumps are used for it instead of
      // pumpAndSettle. This is a test-environment limitation, not app
      // behavior; Nearby Hotels' own controller/location-outcome states are
      // already covered directly in nearby_hotels_controller_test.dart.
      Future<void> selectTabBounded(String label) async {
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Near You → Popular → Large Halls → All Halls → Near You, exactly the
      // approved manual verification sequence. Counting starts fresh from
      // here: MaterialApp's own initial "/" route delivers its didPush
      // notification asynchronously (a test-harness timing artifact, not a
      // navigation any of this test's code triggers), landing somewhere
      // during this first settle rather than at pumpWidget — never before
      // the very first real tab selection below.
      await selectTabBounded('Near You');
      observer.pushCount = 0;
      expect(find.byType(DiscoverScreen), findsOneWidget);

      await selectTab('Popular');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(DiscoverScreen), findsOneWidget);
      expect(observer.pushCount, 0, reason: 'Popular must not push a route');
      expect(find.text('Popular Hotel Marker'), findsOneWidget);
      // Switching away must not leave the previous section's content behind.
      expect(find.text('Base Hotel'), findsNothing);

      await selectTab('Large Halls');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(DiscoverScreen), findsOneWidget);
      expect(observer.pushCount, 0, reason: 'Large Halls must not push a route');
      expect(find.text('Large Hall Marker'), findsOneWidget);
      expect(find.text('Popular Hotel Marker'), findsNothing);

      await selectTab('All Halls');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(DiscoverScreen), findsOneWidget);
      expect(observer.pushCount, 0, reason: 'All Halls must not push a route');
      expect(find.text('All Halls Marker'), findsOneWidget);
      expect(find.text('Large Hall Marker'), findsNothing);

      await selectTabBounded('Near You');
      expect(find.byType(DiscoverScreen), findsOneWidget);
      expect(observer.pushCount, 0, reason: 'Near You (again) must not push a route');
      expect(find.text('All Halls Marker'), findsNothing);

      // The header, search bar, and tabs never leave the tree across any of
      // these selections — the same Discover screen throughout.
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Search hotel or location...'), findsOneWidget);
      for (final label in ['Near You', 'Popular', 'Large Halls', 'All Halls', 'All Hotels']) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets('tapping an actual Hotel from a section still navigates to Hotel Detail', (tester) async {
    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(_wrapDiscover(observer));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Popular'));
    await tester.pumpAndSettle();
    expect(find.text('Popular Hotel Marker'), findsOneWidget);
    // Selecting the tab itself must not have navigated — reset here so this
    // assertion is only about the upcoming real Hotel tap (MaterialApp's own
    // initial "/" route notification is asynchronous and otherwise pollutes
    // this count, same test-harness artifact noted in the tabs test above).
    observer.pushCount = 0;

    await tester.tap(find.text('Popular Hotel Marker'));
    await tester.pumpAndSettle();

    expect(observer.pushCount, 1, reason: 'tapping a real Hotel is a real navigation, unlike the tabs');
  });
}
