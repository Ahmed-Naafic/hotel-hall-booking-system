import 'package:customer_mobile/features/discovery/application/large_halls_controller.dart';
import 'package:customer_mobile/features/discovery/data/discovery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/testing.dart';

import '../../test_support.dart';

void main() {
  test('loads large Halls successfully, preserving backend order and Hotel name', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => successResponse([
          {
            'id': 'hall-1',
            'hotelId': 'hotel-1',
            'profileData': {'name': 'Main Conference Hall', 'capacity': 500},
            'photos': [],
            'hotel': {'id': 'hotel-1', 'name': 'Silver Star Hotel'},
          },
          {
            'id': 'hall-2',
            'hotelId': 'hotel-2',
            'profileData': {'name': 'Grand Ballroom', 'capacity': 400},
            'photos': [],
            'hotel': {'id': 'hotel-2', 'name': 'Liido Beach Hotel'},
          },
        ]),
      ),
      baseUrl: 'http://test/api/v1',
    );
    final controller = LargeHallsController(DiscoveryRepository(client));

    await controller.load();

    expect(controller.state, LargeHallsState.loaded);
    expect(controller.halls.map((h) => h.id), ['hall-1', 'hall-2']);
    expect(controller.halls.first.hotelName, 'Silver Star Hotel');
    expect(controller.halls.first.capacity, '500');
  });

  test('zero results is an empty state, not an error', () async {
    final client = ApiClient(
      httpClient: MockClient((_) async => successResponse([])),
      baseUrl: 'http://test/api/v1',
    );
    final controller = LargeHallsController(DiscoveryRepository(client));

    await controller.load();

    expect(controller.state, LargeHallsState.empty);
    expect(controller.halls, isEmpty);
  });

  test('a backend/network failure is a retryable error', () async {
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
    final controller = LargeHallsController(DiscoveryRepository(client));

    await controller.load();
    expect(controller.state, LargeHallsState.error);
    expect(controller.errorMessage, isNotNull);

    await controller.load();
    expect(controller.state, LargeHallsState.empty);
  });

  test('a Hall with no hotel field falls back to a null hotel name', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => successResponse([
          {
            'id': 'hall-1',
            'hotelId': 'hotel-1',
            'profileData': {'name': 'Legacy Hall', 'capacity': 100},
            'photos': [],
          },
        ]),
      ),
      baseUrl: 'http://test/api/v1',
    );
    final controller = LargeHallsController(DiscoveryRepository(client));

    await controller.load();

    expect(controller.halls.single.hotelName, isNull);
  });
}
