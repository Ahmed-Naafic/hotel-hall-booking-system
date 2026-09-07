import 'package:customer_mobile/features/discovery/application/popular_hotels_controller.dart';
import 'package:customer_mobile/features/discovery/data/discovery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/testing.dart';

import '../../test_support.dart';

void main() {
  test('loads popular Hotels successfully, preserving backend order', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => successResponse([
          {
            'id': 'h1',
            'profileData': {'name': 'Busy Hotel'},
            'logo': null,
            'photos': [],
            'bookingCount': 12,
          },
          {
            'id': 'h2',
            'profileData': {'name': 'Quieter Hotel'},
            'logo': null,
            'photos': [],
            'bookingCount': 3,
          },
        ]),
      ),
      baseUrl: 'http://test/api/v1',
    );
    final controller = PopularHotelsController(DiscoveryRepository(client));

    await controller.load();

    expect(controller.state, PopularHotelsState.loaded);
    expect(controller.hotels.map((h) => h.id), ['h1', 'h2']);
    expect(controller.hotels.first.bookingCount, 12);
  });

  test('zero results is an empty state, not an error', () async {
    final client = ApiClient(
      httpClient: MockClient((_) async => successResponse([])),
      baseUrl: 'http://test/api/v1',
    );
    final controller = PopularHotelsController(DiscoveryRepository(client));

    await controller.load();

    expect(controller.state, PopularHotelsState.empty);
    expect(controller.hotels, isEmpty);
  });

  test('a backend/network failure is a retryable error', () async {
    var attempts = 0;
    final client = ApiClient(
      httpClient: MockClient((_) async {
        attempts++;
        return attempts == 1
            ? errorResponse('INTERNAL_SERVER_ERROR', 'failed', 500)
            : successResponse([
                {
                  'id': 'h1',
                  'profileData': {'name': 'Busy Hotel'},
                  'logo': null,
                  'photos': [],
                  'bookingCount': 5,
                },
              ]);
      }),
      baseUrl: 'http://test/api/v1',
    );
    final controller = PopularHotelsController(DiscoveryRepository(client));

    await controller.load();
    expect(controller.state, PopularHotelsState.error);
    expect(controller.errorMessage, isNotNull);

    await controller.load();
    expect(controller.state, PopularHotelsState.loaded);
  });

  test('loading state is set immediately when load starts', () {
    final client = ApiClient(
      httpClient: MockClient((_) async => successResponse([])),
      baseUrl: 'http://test/api/v1',
    );
    final controller = PopularHotelsController(DiscoveryRepository(client));
    expect(controller.state, PopularHotelsState.loading);
  });

  test('markStale sets isStale without refetching on its own', () async {
    var requestCount = 0;
    final client = ApiClient(
      httpClient: MockClient((_) async {
        requestCount++;
        return successResponse([]);
      }),
      baseUrl: 'http://test/api/v1',
    );
    final controller = PopularHotelsController(DiscoveryRepository(client));
    await controller.load();
    expect(requestCount, 1);

    controller.markStale();

    expect(controller.isStale, true);
    expect(requestCount, 1, reason: 'markStale must never itself trigger a fetch');
  });

  test('load() clears isStale, whether just marked stale or freshly constructed', () async {
    final client = ApiClient(
      httpClient: MockClient((_) async => successResponse([])),
      baseUrl: 'http://test/api/v1',
    );
    final controller = PopularHotelsController(DiscoveryRepository(client));
    controller.markStale();
    expect(controller.isStale, true);

    await controller.load();

    expect(controller.isStale, false);
  });
}
