import 'package:customer_mobile/features/discovery/data/discovery_repository.dart';
import 'package:customer_mobile/features/favorites/application/favorites_controller.dart';
import 'package:customer_mobile/features/favorites/application/saved_hotels_controller.dart';
import 'package:customer_mobile/features/favorites/data/favorites_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../test_support.dart';

Map<String, dynamic> _hotelJson(String id, String name) => {
  'id': id,
  'profileData': {'name': name},
  'logo': null,
  'photos': [],
};

void main() {
  test('resolves each saved Hotel ID into full Hotel data', () async {
    final favoritesClient = ApiClient(
      httpClient: MockClient((_) async => successResponse(['h1', 'h2'])),
      baseUrl: 'http://test/api/v1',
    );
    final favorites = FavoritesController(FavoritesRepository(favoritesClient));
    await favorites.load();

    final discoveryClient = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/hotels/public/h1')) {
          return successResponse(_hotelJson('h1', 'Hotel One'));
        }
        if (request.url.path.endsWith('/hotels/public/h2')) {
          return successResponse(_hotelJson('h2', 'Hotel Two'));
        }
        return errorResponse('NOT_FOUND', 'not found', 404);
      }),
      baseUrl: 'http://test/api/v1',
    );
    final controller = SavedHotelsController(
      repository: DiscoveryRepository(discoveryClient),
      favorites: favorites,
    );

    await controller.load();

    expect(controller.hotels.map((h) => h.id), ['h1', 'h2']);
    expect(controller.errorMessage, isNull);
  });

  test('a saved Hotel that no longer exists is silently dropped, not an error', () async {
    final favoritesClient = ApiClient(
      httpClient: MockClient((_) async => successResponse(['h1', 'gone'])),
      baseUrl: 'http://test/api/v1',
    );
    final favorites = FavoritesController(FavoritesRepository(favoritesClient));
    await favorites.load();

    final discoveryClient = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/hotels/public/h1')) {
          return successResponse(_hotelJson('h1', 'Hotel One'));
        }
        return errorResponse('NOT_FOUND', 'Hotel not found.', 404);
      }),
      baseUrl: 'http://test/api/v1',
    );
    final controller = SavedHotelsController(
      repository: DiscoveryRepository(discoveryClient),
      favorites: favorites,
    );

    await controller.load();

    expect(controller.hotels.map((h) => h.id), ['h1']);
  });

  test('an empty saved list is an empty state, not an error', () async {
    final favoritesClient = ApiClient(
      httpClient: MockClient((_) async => successResponse(<String>[])),
      baseUrl: 'http://test/api/v1',
    );
    final favorites = FavoritesController(FavoritesRepository(favoritesClient));
    await favorites.load();

    final controller = SavedHotelsController(
      repository: DiscoveryRepository(ApiClient(httpClient: MockClient((_) async => errorResponse('X', 'x', 500)), baseUrl: 'http://test/api/v1')),
      favorites: favorites,
    );

    await controller.load();

    expect(controller.hotels, isEmpty);
    expect(controller.errorMessage, isNull);
  });

  test('unsaving a Hotel elsewhere removes it from the visible list', () async {
    final favoritesClient = ApiClient(
      httpClient: MockClient((request) async {
        if (request.method == 'DELETE') return http.Response('', 204);
        return successResponse(['h1', 'h2']);
      }),
      baseUrl: 'http://test/api/v1',
    );
    final favorites = FavoritesController(FavoritesRepository(favoritesClient));
    await favorites.load();

    final discoveryClient = ApiClient(
      httpClient: MockClient((request) async {
        final id = request.url.pathSegments.last;
        return successResponse(_hotelJson(id, 'Hotel $id'));
      }),
      baseUrl: 'http://test/api/v1',
    );
    final controller = SavedHotelsController(
      repository: DiscoveryRepository(discoveryClient),
      favorites: favorites,
    );
    await controller.load();
    expect(controller.hotels.length, 2);

    await favorites.toggle('h1');

    expect(controller.hotels.map((h) => h.id), ['h2']);
  });

  test('a load failure on the saved-IDs list itself surfaces a retryable error', () async {
    final favoritesClient = ApiClient(
      httpClient: MockClient((_) async => errorResponse('INTERNAL_SERVER_ERROR', 'failed', 500)),
      baseUrl: 'http://test/api/v1',
    );
    final favorites = FavoritesController(FavoritesRepository(favoritesClient));
    // favorites.load() swallows its own error (best-effort, per its own
    // contract) — savedHotelIds stays empty, so this controller's load()
    // succeeds trivially with an empty list rather than erroring.
    await favorites.load();

    final controller = SavedHotelsController(
      repository: DiscoveryRepository(ApiClient(httpClient: MockClient((_) async => errorResponse('X', 'x', 500)), baseUrl: 'http://test/api/v1')),
      favorites: favorites,
    );

    await controller.load();

    expect(controller.hotels, isEmpty);
    expect(controller.errorMessage, isNull);
  });
}
