import 'dart:convert';

import 'package:customer_mobile/core/pending_action_controller.dart';
import 'package:customer_mobile/features/discovery/application/discovery_controller.dart';
import 'package:customer_mobile/features/discovery/application/popular_hotels_controller.dart';
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

/// Discover search, asserted on **rendered results** rather than on the
/// requests that produced them.
///
/// `discover_screen_search_test.dart` already proves the four category
/// endpoints are *called* with `search`; that is what let the tabs ship
/// showing an unfiltered list for a live query — the request went out, its
/// response lost a race, and nothing checked what was on screen. Every
/// expectation below is a list the customer can actually see.
///
/// The fake backend here matches the way the real one does — case-
/// insensitive substring, on the fields each endpoint actually searches
/// (`hotel.service.js#hotelMatchesSearch`, `visibility.service.js#hallMatchesSearch`,
/// `hall.repository.js#browseSearchWhere`) — and preserves each endpoint's
/// own ordering, so an ordering regression shows up here too.
///
/// Near You is deliberately absent: geolocator has no platform
/// implementation under `flutter test`, so its controller can never reach a
/// located state here. Its search behaviour — with location available and
/// unavailable — is covered directly in `discovery_search_race_test.dart`.

// ---------------------------------------------------------------------------
// Fake backend
// ---------------------------------------------------------------------------

/// Hotels, already in the order `/hotels/public/popular` ranks them
/// (most qualifying Bookings first).
const _hotels = [
  (id: 'h-guuleed', name: 'Guuleed Palace', bookings: 9),
  (id: 'h-jazeera', name: 'Jazeera Suites', bookings: 5),
  (id: 'h-annex', name: 'GUULEED Annex', bookings: 2),
];

/// Halls, already in the order `/halls/large-capacity` ranks them
/// (largest capacity first). `hotelName` below is deliberately
/// non-matching so a Hall-name search cannot accidentally pass via the
/// Hotel-name match that only `GET /halls` performs.
const _halls = [
  (id: 'hall-grand', name: 'Guuleed Grand Hall', capacity: 900),
  (id: 'hall-ball', name: 'Jazeera Ballroom', capacity: 400),
  (id: 'hall-terrace', name: 'Guuleed Terrace', capacity: 100),
];

const _parentHotelName = 'Parent Property';

bool _matches(String name, String? search) =>
    search == null ||
    search.isEmpty ||
    name.toLowerCase().contains(search.toLowerCase());

http.Response _envelope(dynamic data, {Map<String, dynamic>? pagination}) =>
    http.Response(
      jsonEncode({
        'status': 'success',
        'message': 'ok',
        'data': data,
        'pagination': ?pagination,
      }),
      200,
    );

Map<String, dynamic> _hotelJson(({String id, String name, int bookings}) hotel) => {
  'id': hotel.id,
  'profileData': {'name': hotel.name},
  'logo': null,
  'photos': [],
};

Map<String, dynamic> _hallJson(({String id, String name, int capacity}) hall) => {
  'id': hall.id,
  'hotelId': 'hotel-1',
  'profileData': {'name': hall.name, 'capacity': hall.capacity},
  'photos': [],
  'hotel': {'id': 'hotel-1', 'name': _parentHotelName},
};

/// Every request the screen made, in order — used to assert that a tab is
/// fetched once for a query, and never refetched when already correct.
final List<Uri> requestLog = [];

Future<http.Response> _handle(http.Request request) async {
  requestLog.add(request.url);
  final path = request.url.path;
  final search = request.url.queryParameters['search'];

  if (path.endsWith('/favorites/hotels')) return _envelope(<String>[]);

  if (path.endsWith('/hotels/public/popular')) {
    return _envelope([
      for (final hotel in _hotels)
        if (_matches(hotel.name, search))
          {..._hotelJson(hotel), 'bookingCount': hotel.bookings},
    ]);
  }

  if (path.endsWith('/halls/large-capacity')) {
    return _envelope([
      for (final hall in _halls)
        if (_matches(hall.name, search)) _hallJson(hall),
    ]);
  }

  if (path.endsWith('/hotels/public')) {
    // Cursor pagination over the matching set, the way `GET /hotels/public`
    // pages: `cursor` is the last id of the previous page.
    final matching = [
      for (final hotel in _hotels)
        if (_matches(hotel.name, search)) hotel,
    ];
    final cursor = request.url.queryParameters['cursor'];
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '') ?? 20;
    final start = cursor == null
        ? 0
        : matching.indexWhere((hotel) => hotel.id == cursor) + 1;
    final page = matching.skip(start).take(limit).toList();
    final hasNext = start + page.length < matching.length;
    return _envelope(
      page.map(_hotelJson).toList(),
      pagination: {
        'limit': limit,
        'hasNext': hasNext,
        'nextCursor': hasNext ? page.last.id : null,
      },
    );
  }

  if (path.endsWith('/halls')) {
    // `GET /halls` matches Hall name **or** owning Hotel name.
    final matching = [
      for (final hall in _halls)
        if (_matches(hall.name, search) || _matches(_parentHotelName, search))
          hall,
    ];
    return _envelope(
      matching.map(_hallJson).toList(),
      pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
    );
  }

  // /hotels/public/nearby — never reached in a widget test (see the file
  // comment); an empty list keeps an unexpected call from hanging.
  return _envelope([]);
}

Widget _wrapDiscover() {
  final apiClient = ApiClient(
    httpClient: MockClient(_handle),
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
      ChangeNotifierProvider(
        create: (_) => PopularHotelsController(DiscoveryRepository(apiClient)),
      ),
    ],
    child: const MaterialApp(home: DiscoverScreen()),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Types `query`, then lets the 400 ms debounce fire and every resulting
/// request settle.
Future<void> _searchFor(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _selectTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

int _callsTo(String pathSuffix) =>
    requestLog.where((uri) => uri.path.endsWith(pathSuffix)).length;

void main() {
  setUp(requestLog.clear);

  testWidgets('All Hotels shows only matching Hotels, and drops the rest', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapDiscover());
    await tester.pumpAndSettle();

    expect(find.text('Jazeera Suites'), findsWidgets);

    await _searchFor(tester, 'guuleed');

    expect(find.text('Guuleed Palace'), findsWidgets);
    expect(find.text('GUULEED Annex'), findsWidgets);
    expect(find.text('Jazeera Suites'), findsNothing);
  });

  testWidgets('Popular shows only matching Hotels, keeping popularity order', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapDiscover());
    await tester.pumpAndSettle();

    await _searchFor(tester, 'guuleed');
    await _selectTab(tester, 'Popular');

    expect(find.text('Jazeera Suites'), findsNothing);
    // Guuleed Palace (9 bookings) must still rank above GUULEED Annex (2).
    final palace = tester.getTopLeft(find.text('Guuleed Palace').first).dy;
    final annex = tester.getTopLeft(find.text('GUULEED Annex').first).dy;
    expect(palace, lessThan(annex));
  });

  testWidgets('Large Halls shows only matching Halls, keeping capacity order', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapDiscover());
    await tester.pumpAndSettle();

    await _searchFor(tester, 'guuleed');
    await _selectTab(tester, 'Large Halls');

    expect(find.text('Jazeera Ballroom'), findsNothing);
    // Grand Hall (900) must still rank above Terrace (100).
    final grand = tester.getTopLeft(find.text('Guuleed Grand Hall').first).dy;
    final terrace = tester.getTopLeft(find.text('Guuleed Terrace').first).dy;
    expect(grand, lessThan(terrace));
  });

  testWidgets('All Halls shows only matching Halls', (tester) async {
    await tester.pumpWidget(_wrapDiscover());
    await tester.pumpAndSettle();

    await _searchFor(tester, 'guuleed');
    await _selectTab(tester, 'All Halls');

    expect(find.text('Guuleed Grand Hall'), findsWidgets);
    expect(find.text('Guuleed Terrace'), findsWidgets);
    expect(find.text('Jazeera Ballroom'), findsNothing);
  });

  testWidgets(
    'a query typed on one tab is already applied when another tab is opened',
    (tester) async {
      await tester.pumpWidget(_wrapDiscover());
      await tester.pumpAndSettle();

      // Typed while "All Hotels" is showing — the other tabs were never opened.
      await _searchFor(tester, 'jazeera');

      await _selectTab(tester, 'Popular');
      expect(find.text('Jazeera Suites'), findsWidgets);
      expect(find.text('Guuleed Palace'), findsNothing);

      await _selectTab(tester, 'Large Halls');
      expect(find.text('Jazeera Ballroom'), findsWidgets);
      expect(find.text('Guuleed Grand Hall'), findsNothing);

      await _selectTab(tester, 'All Halls');
      expect(find.text('Jazeera Ballroom'), findsWidgets);
      expect(find.text('Guuleed Grand Hall'), findsNothing);

      // ...and back again, still filtered.
      await _selectTab(tester, 'All Hotels');
      expect(find.text('Jazeera Suites'), findsWidgets);
      expect(find.text('Guuleed Palace'), findsNothing);
    },
  );

  testWidgets('search is case-insensitive and matches partial names', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapDiscover());
    await tester.pumpAndSettle();

    // A lowercase fragment, matching only part of a mixed-case word.
    await _searchFor(tester, 'uulee');

    expect(find.text('Guuleed Palace'), findsWidgets);
    expect(find.text('GUULEED Annex'), findsWidgets);
    expect(find.text('Jazeera Suites'), findsNothing);

    await _selectTab(tester, 'Large Halls');
    expect(find.text('Guuleed Grand Hall'), findsWidgets);
    expect(find.text('Jazeera Ballroom'), findsNothing);
  });

  testWidgets('clearing the search restores every tab, not just the one showing', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapDiscover());
    await tester.pumpAndSettle();

    await _searchFor(tester, 'guuleed');
    await _selectTab(tester, 'Large Halls');
    expect(find.text('Jazeera Ballroom'), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // The tab that was showing when the search was cleared.
    expect(find.text('Jazeera Ballroom'), findsWidgets);

    await _selectTab(tester, 'All Halls');
    expect(find.text('Jazeera Ballroom'), findsWidgets);

    await _selectTab(tester, 'Popular');
    expect(find.text('Jazeera Suites'), findsWidgets);

    await _selectTab(tester, 'All Hotels');
    expect(find.text('Jazeera Suites'), findsWidgets);
  });

  testWidgets(
    'a query matching nothing empties the list rather than leaving it unfiltered',
    (tester) async {
      await tester.pumpWidget(_wrapDiscover());
      await tester.pumpAndSettle();

      await _searchFor(tester, 'zzzznomatch');

      expect(find.text('Guuleed Palace'), findsNothing);
      expect(find.text('Jazeera Suites'), findsNothing);
      // The empty state names the query rather than claiming nothing exists.
      expect(find.textContaining('zzzznomatch'), findsWidgets);

      await _selectTab(tester, 'Large Halls');
      expect(find.text('Guuleed Grand Hall'), findsNothing);
      expect(find.text('Jazeera Ballroom'), findsNothing);

      await _selectTab(tester, 'All Halls');
      expect(find.text('Guuleed Grand Hall'), findsNothing);
      expect(find.text('Jazeera Ballroom'), findsNothing);

      await _selectTab(tester, 'Popular');
      expect(find.text('Guuleed Palace'), findsNothing);
      expect(find.text('Jazeera Suites'), findsNothing);
    },
  );

  testWidgets('a searched tab is fetched exactly once, then not refetched on open', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapDiscover());
    await tester.pumpAndSettle();

    await _searchFor(tester, 'guuleed');

    // Exactly one request for the live query — not an unsearched load
    // followed by a searched one, which is the race this guards.
    expect(_callsTo('/halls/large-capacity'), 1);
    expect(
      requestLog
          .where((uri) => uri.path.endsWith('/halls/large-capacity'))
          .single
          .queryParameters['search'],
      'guuleed',
    );

    final before = _callsTo('/halls/large-capacity');
    await _selectTab(tester, 'Large Halls');
    expect(_callsTo('/halls/large-capacity'), before);
    expect(find.text('Jazeera Ballroom'), findsNothing);
  });

  testWidgets(
    'typing never requests Nearby Hotels, so it cannot raise a location prompt',
    (tester) async {
      await tester.pumpWidget(_wrapDiscover());
      await tester.pumpAndSettle();

      await _searchFor(tester, 'guuleed');
      await _selectTab(tester, 'Popular');
      await _selectTab(tester, 'All Halls');

      expect(_callsTo('/hotels/public/nearby'), 0);
    },
  );
}
