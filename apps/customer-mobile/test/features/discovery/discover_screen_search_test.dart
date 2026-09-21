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

/// Covers the Customer Mobile side of Hotel Search (`BDR-020`): the search
/// bar calls the backend (debounced), never filters a locally-loaded page —
/// see `discovery_controller_test.dart` for the controller-level contract
/// this screen builds on.
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

Widget _wrapDiscover({
  required Future<http.Response> Function(http.Request request) handler,
}) {
  final apiClient = ApiClient(
    httpClient: MockClient(handler),
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

void main() {
  testWidgets('typing in the search bar is debounced — no request until typing pauses', (tester) async {
    var searchCallCount = 0;
    await tester.pumpWidget(
      _wrapDiscover(
        handler: (request) async {
          if (request.url.path.endsWith('/favorites/hotels')) return _envelope(<String>[]);
          if (request.url.path.endsWith('/hotels/public')) {
            if (request.url.queryParameters.containsKey('search')) searchCallCount++;
            return _envelope([_hotelJson('base-1', 'Base Hotel')]);
          }
          return _envelope([]);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'G');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'Gu');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'Guuleed');
    // Still well under the 400ms debounce window since the last keystroke.
    await tester.pump(const Duration(milliseconds: 100));
    expect(searchCallCount, 0, reason: 'no request should fire while still typing');

    await tester.pump(const Duration(milliseconds: 400));
    expect(searchCallCount, 1, reason: 'exactly one request once typing pauses');
  });

  testWidgets('a search result replaces the unsearched Hotel list', (tester) async {
    await tester.pumpWidget(
      _wrapDiscover(
        handler: (request) async {
          if (request.url.path.endsWith('/favorites/hotels')) return _envelope(<String>[]);
          if (request.url.path.endsWith('/hotels/public')) {
            if (request.url.queryParameters['search'] == 'Guuleed') {
              return _envelope(
                [_hotelJson('h1', 'Hotel Guuleed')],
                pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
              );
            }
            return _envelope([_hotelJson('base-1', 'Base Hotel')]);
          }
          return _envelope([]);
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Base Hotel'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Guuleed');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Hotel Guuleed'), findsOneWidget);
    expect(find.text('Base Hotel'), findsNothing);
    expect(find.text('Search results'), findsOneWidget);
    // The curated carousel only applies to the unsearched browse.
    expect(find.text('Featured hotels'), findsNothing);
  });

  testWidgets('a search with no matches shows the empty state, naming the query', (tester) async {
    await tester.pumpWidget(
      _wrapDiscover(
        handler: (request) async {
          if (request.url.path.endsWith('/favorites/hotels')) return _envelope(<String>[]);
          if (request.url.path.endsWith('/hotels/public')) {
            if (request.url.queryParameters.containsKey('search')) {
              return _envelope([], pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null});
            }
            return _envelope([_hotelJson('base-1', 'Base Hotel')]);
          }
          return _envelope([]);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'NoSuchHotel');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('No Hotels match "NoSuchHotel".'), findsOneWidget);
  });

  testWidgets('a search failure shows a retryable error state', (tester) async {
    await tester.pumpWidget(
      _wrapDiscover(
        handler: (request) async {
          if (request.url.path.endsWith('/favorites/hotels')) return _envelope(<String>[]);
          if (request.url.path.endsWith('/hotels/public')) {
            if (request.url.queryParameters.containsKey('search')) {
              return errorResponse('INTERNAL_SERVER_ERROR', 'failed', 500);
            }
            return _envelope([_hotelJson('base-1', 'Base Hotel')]);
          }
          return _envelope([]);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Guuleed');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Could not search Hotels. Please try again.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('clearing the search restores the unsearched Hotel list', (tester) async {
    await tester.pumpWidget(
      _wrapDiscover(
        handler: (request) async {
          if (request.url.path.endsWith('/favorites/hotels')) return _envelope(<String>[]);
          if (request.url.path.endsWith('/hotels/public')) {
            if (request.url.queryParameters['search'] == 'Guuleed') {
              return _envelope(
                [_hotelJson('h1', 'Hotel Guuleed')],
                pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
              );
            }
            return _envelope([_hotelJson('base-1', 'Base Hotel')]);
          }
          return _envelope([]);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Guuleed');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Hotel Guuleed'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Base Hotel'), findsWidgets);
    expect(find.text('Hotel Guuleed'), findsNothing);
    expect(find.widgetWithText(TextField, 'Guuleed'), findsNothing);
  });

  testWidgets(
    'typing also searches Popular, Large Halls, and All Halls in the background, not just All Hotels',
    (tester) async {
      final searchedPaths = <String>{};
      await tester.pumpWidget(
        _wrapDiscover(
          handler: (request) async {
            if (request.url.path.endsWith('/favorites/hotels')) return _envelope(<String>[]);
            if (request.url.queryParameters['search'] == 'Guuleed') {
              searchedPaths.add(request.url.path);
            }
            if (request.url.path.endsWith('/halls')) {
              return _envelope([], pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null});
            }
            return _envelope([]);
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Guuleed');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(
        searchedPaths,
        containsAll(<String>{
          '/api/v1/hotels/public',
          '/api/v1/hotels/public/popular',
          '/api/v1/halls/large-capacity',
          '/api/v1/halls',
        }),
      );
    },
  );

  testWidgets('a search result page with more results shows the pagination footer', (tester) async {
    await tester.pumpWidget(
      _wrapDiscover(
        handler: (request) async {
          if (request.url.path.endsWith('/favorites/hotels')) return _envelope(<String>[]);
          if (request.url.path.endsWith('/hotels/public')) {
            if (request.url.queryParameters.containsKey('search')) {
              return _envelope(
                [_hotelJson('h1', 'Hotel Guuleed 1')],
                pagination: {'limit': 20, 'hasNext': true, 'nextCursor': 'h1'},
              );
            }
            return _envelope([_hotelJson('base-1', 'Base Hotel')]);
          }
          return _envelope([]);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Guuleed');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Hotel Guuleed 1'), findsOneWidget);
    // The scroll-triggered `loadMoreSearchResults` call itself is covered at
    // the controller level (`discovery_controller_test.dart`) — this only
    // confirms the screen renders the pagination footer when more results
    // exist, the actual new integration point here.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
