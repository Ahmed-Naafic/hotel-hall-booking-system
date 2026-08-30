import 'package:customer_mobile/core/pending_action_controller.dart';
import 'package:customer_mobile/features/discovery/application/discovery_controller.dart';
import 'package:customer_mobile/features/discovery/data/discovery_models.dart';
import 'package:customer_mobile/features/discovery/data/discovery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/testing.dart';

import '../../test_support.dart';

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
}
