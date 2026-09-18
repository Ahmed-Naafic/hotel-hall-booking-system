import 'dart:convert';

import 'package:customer_mobile/core/pending_action_controller.dart';
import 'package:customer_mobile/features/discovery/application/discovery_controller.dart';
import 'package:customer_mobile/features/discovery/data/discovery_models.dart';
import 'package:customer_mobile/features/discovery/data/discovery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../test_support.dart';

http.Response _pagedEnvelope(List<dynamic> data, {required bool hasNext, String? nextCursor}) =>
    http.Response(
      jsonEncode({
        'status': 'success',
        'message': 'ok',
        'data': data,
        'pagination': {'limit': 20, 'hasNext': hasNext, 'nextCursor': nextCursor},
      }),
      200,
    );

Map<String, dynamic> _hotelJson(String id, String name) => {
  'id': id,
  'profileData': {'name': name},
  'logo': null,
  'photos': [],
};

void main() {
  test('loads public Hotels successfully', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => successResponse([
          {
            'id': 'h1',
            'profileData': {'name': 'City Hotel'},
            'logo': null,
            'photos': [],
          },
        ]),
      ),
      baseUrl: 'http://test/api/v1',
    );
    final controller = DiscoveryController(DiscoveryRepository(client));
    await controller.loadHotels();
    expect(controller.hotels.single.name, 'City Hotel');
    expect(controller.errorMessage, isNull);
  });

  test('represents an empty Hotel result', () async {
    final client = ApiClient(
      httpClient: MockClient((_) async => successResponse([])),
      baseUrl: 'http://test/api/v1',
    );
    final controller = DiscoveryController(DiscoveryRepository(client));
    await controller.loadHotels();
    expect(controller.hotels, isEmpty);
  });

  test('represents a discovery API failure and supports retry', () async {
    var attempts = 0;
    final client = ApiClient(
      httpClient: MockClient((_) async {
        attempts++;
        return attempts == 1
            ? errorResponse('INTERNAL_SERVER_ERROR', 'failed', 500)
            : successResponse([]);
      }),
      baseUrl: 'http://test/api/v1',
    );
    final controller = DiscoveryController(DiscoveryRepository(client));
    await controller.loadHotels();
    expect(controller.errorMessage, isNotNull);
    await controller.loadHotels();
    expect(controller.errorMessage, isNull);
  });

  test('preserves and consumes the selected Hall protected-action context', () {
    final pending = PendingActionController();
    const hall = HallSummary(
      id: 'hall-1',
      hotelId: 'hotel-1',
      profileData: {'name': 'Grand Hall'},
    );
    pending.preserveBookingHall(hall);
    expect(pending.hall?.id, 'hall-1');
    expect(pending.takeHall()?.id, 'hall-1');
    expect(pending.hall, isNull);
  });

  test('parses Hotel and Hall details from authoritative DTOs', () async {
    final client = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/hotels/public/h1')) {
          return successResponse({
            'id': 'h1',
            'profileData': {'name': 'City Hotel'},
            'logo': null,
            'photos': [],
          });
        }
        return successResponse([
          {
            'id': 'hall-1',
            'hotelId': 'h1',
            'profileData': {'name': 'Grand Hall', 'capacity': 120},
            'photos': [],
          },
        ]);
      }),
      baseUrl: 'http://test/api/v1',
    );
    final repository = DiscoveryRepository(client);
    expect((await repository.getHotel('h1')).name, 'City Hotel');
    expect((await repository.getHalls('h1')).single.capacity, '120');
  });

  group('Hotel Search (BDR-020)', () {
    test('search sends the query server-side and replaces hotels with the results', () async {
      Uri? capturedUrl;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          capturedUrl = request.url;
          return _pagedEnvelope([_hotelJson('h1', 'Hotel Guuleed')], hasNext: false);
        }),
        baseUrl: 'http://test/api/v1',
      );
      final controller = DiscoveryController(DiscoveryRepository(client));

      await controller.search('Guuleed');

      expect(controller.hotels.single.name, 'Hotel Guuleed');
      expect(controller.isSearchActive, true);
      expect(controller.errorMessage, isNull);
      expect(capturedUrl?.queryParameters['search'], 'Guuleed');
    });

    test('a blank query clears back to the plain unsearched browse', () async {
      var callCount = 0;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          callCount++;
          if (request.url.queryParameters.containsKey('search')) {
            return _pagedEnvelope([_hotelJson('h1', 'Hotel Guuleed')], hasNext: false);
          }
          return successResponse([_hotelJson('base-1', 'Base Hotel')]);
        }),
        baseUrl: 'http://test/api/v1',
      );
      final controller = DiscoveryController(DiscoveryRepository(client));

      await controller.search('Guuleed');
      expect(controller.isSearchActive, true);

      await controller.search('   ');
      expect(controller.isSearchActive, false);
      expect(controller.hotels.single.name, 'Base Hotel');
      expect(callCount, 2);
    });

    test('a search with no matches is an empty result, not an error', () async {
      final client = ApiClient(
        httpClient: MockClient((_) async => _pagedEnvelope([], hasNext: false)),
        baseUrl: 'http://test/api/v1',
      );
      final controller = DiscoveryController(DiscoveryRepository(client));

      await controller.search('NoSuchHotel');

      expect(controller.hotels, isEmpty);
      expect(controller.errorMessage, isNull);
      expect(controller.isSearchActive, true);
    });

    test('a backend failure while searching surfaces a retryable error', () async {
      final client = ApiClient(
        httpClient: MockClient(
          (_) async => errorResponse('INTERNAL_SERVER_ERROR', 'failed', 500),
        ),
        baseUrl: 'http://test/api/v1',
      );
      final controller = DiscoveryController(DiscoveryRepository(client));

      await controller.search('Guuleed');

      expect(controller.errorMessage, isNotNull);
      expect(controller.hotels, isEmpty);
    });

    test('loadMoreSearchResults appends the next page using the returned cursor', () async {
      final requestedCursors = <String?>[];
      final client = ApiClient(
        httpClient: MockClient((request) async {
          requestedCursors.add(request.url.queryParameters['cursor']);
          if (request.url.queryParameters['cursor'] == null) {
            return _pagedEnvelope([_hotelJson('h1', 'Hotel A')], hasNext: true, nextCursor: 'h1');
          }
          return _pagedEnvelope([_hotelJson('h2', 'Hotel B')], hasNext: false);
        }),
        baseUrl: 'http://test/api/v1',
      );
      final controller = DiscoveryController(DiscoveryRepository(client));

      await controller.search('Hotel');
      expect(controller.hotels.map((h) => h.id), ['h1']);
      expect(controller.hasMoreSearchResults, true);

      await controller.loadMoreSearchResults();
      expect(controller.hotels.map((h) => h.id), ['h1', 'h2']);
      expect(controller.hasMoreSearchResults, false);
      expect(requestedCursors, [null, 'h1']);
    });

    test('loadMoreSearchResults does nothing once hasMoreSearchResults is false', () async {
      var callCount = 0;
      final client = ApiClient(
        httpClient: MockClient((_) async {
          callCount++;
          return _pagedEnvelope([_hotelJson('h1', 'Hotel A')], hasNext: false);
        }),
        baseUrl: 'http://test/api/v1',
      );
      final controller = DiscoveryController(DiscoveryRepository(client));

      await controller.search('Hotel');
      expect(callCount, 1);

      await controller.loadMoreSearchResults();
      expect(callCount, 1, reason: 'no further request once hasMoreSearchResults is false');
    });

    test('loadMoreSearchResults is a no-op when no search is active', () async {
      final client = ApiClient(
        httpClient: MockClient((_) async => successResponse([_hotelJson('h1', 'Base Hotel')])),
        baseUrl: 'http://test/api/v1',
      );
      final controller = DiscoveryController(DiscoveryRepository(client));

      await controller.loadHotels();
      await controller.loadMoreSearchResults();

      expect(controller.hotels.single.name, 'Base Hotel');
      expect(controller.isSearchActive, false);
    });
  });
}
