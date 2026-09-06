import 'dart:convert';

import 'package:customer_mobile/features/discovery/presentation/discover_screen.dart';
import 'package:customer_mobile/features/favorites/application/favorites_controller.dart';
import 'package:customer_mobile/features/favorites/data/favorites_repository.dart';
import 'package:customer_mobile/features/favorites/presentation/saved_hotels_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

http.Response _envelope(dynamic data) => http.Response(
  jsonEncode({'status': 'success', 'message': 'ok', 'data': data}),
  200,
);

Map<String, dynamic> _hotelJson(String id, String name) => {
  'id': id,
  'profileData': {'name': name},
  'logo': null,
  'photos': [],
};

/// Loads [favorites] before building — mirrors production, where Discover's
/// `initState` already loaded it by the time a Customer reaches this screen.
Future<Widget> _wrap({required MockClient httpClient}) async {
  final apiClient = ApiClient(httpClient: httpClient, baseUrl: 'http://test/api/v1');
  final favorites = FavoritesController(FavoritesRepository(apiClient));
  await favorites.load();
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider.value(value: favorites),
    ],
    child: const MaterialApp(home: SavedHotelsScreen()),
  );
}

void main() {
  testWidgets('shows an empty state when nothing is saved', (tester) async {
    await tester.pumpWidget(
      await _wrap(httpClient: MockClient((_) async => _envelope(<String>[]))),
    );
    await tester.pumpAndSettle();

    expect(find.text('No saved Hotels yet'), findsOneWidget);
  });

  testWidgets('lists saved Hotels and navigates to Hotel Detail on tap', (tester) async {
    await tester.pumpWidget(
      await _wrap(
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/favorites/hotels')) return _envelope(['h1']);
          if (path.endsWith('/hotels/public/h1')) return _envelope(_hotelJson('h1', 'Saved Hotel Marker'));
          if (path.endsWith('/halls')) return _envelope([]);
          return _envelope(<String>[]);
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved Hotel Marker'), findsOneWidget);

    await tester.tap(find.text('Saved Hotel Marker'));
    await tester.pumpAndSettle();

    expect(find.byType(HotelDetailScreen), findsOneWidget);
  });

  testWidgets('tapping the bookmark button unsaves and removes the tile', (tester) async {
    await tester.pumpWidget(
      await _wrap(
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (request.method == 'DELETE') return http.Response('', 204);
          if (path.endsWith('/favorites/hotels')) return _envelope(['h1']);
          if (path.endsWith('/hotels/public/h1')) return _envelope(_hotelJson('h1', 'Saved Hotel Marker'));
          return _envelope(<String>[]);
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved Hotel Marker'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Saved Hotel Marker'), findsNothing);
    expect(find.text('No saved Hotels yet'), findsOneWidget);
  });
}
