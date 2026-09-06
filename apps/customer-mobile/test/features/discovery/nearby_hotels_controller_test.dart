import 'package:customer_mobile/core/location_service.dart';
import 'package:customer_mobile/features/discovery/application/nearby_hotels_controller.dart';
import 'package:customer_mobile/features/discovery/data/discovery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/testing.dart';

import '../../test_support.dart';

class _FakeLocationService extends LocationService {
  _FakeLocationService(this.result);
  final LocationResult result;

  @override
  Future<LocationResult> getCurrentLocation() async => result;
}

NearbyHotelsController _controllerWith({
  required LocationResult location,
  required MockClient httpClient,
}) {
  final client = ApiClient(httpClient: httpClient, baseUrl: 'http://test/api/v1');
  return NearbyHotelsController(
    repository: DiscoveryRepository(client),
    locationService: _FakeLocationService(location),
  );
}

void main() {
  test('permission granted with results loads nearest-first', () async {
    final controller = _controllerWith(
      location: const LocationResult(
        outcome: LocationOutcome.granted,
        latitude: -1.28,
        longitude: 36.81,
      ),
      httpClient: MockClient(
        (_) async => successResponse([
          {
            'id': 'h-far',
            'profileData': {'name': 'Far Hotel'},
            'logo': null,
            'photos': [],
            'distanceKm': 4.2,
          },
          {
            'id': 'h-near',
            'profileData': {'name': 'Near Hotel'},
            'logo': null,
            'photos': [],
            'distanceKm': 0.8,
          },
        ]),
      ),
    );

    await controller.load();

    expect(controller.state, NearbyHotelsState.loaded);
    expect(controller.hotels.map((h) => h.id), ['h-far', 'h-near']);
    expect(controller.hotels.first.distanceKm, 4.2);
  });

  test('permission granted with zero results is an empty state, not an error', () async {
    final controller = _controllerWith(
      location: const LocationResult(
        outcome: LocationOutcome.granted,
        latitude: -1.28,
        longitude: 36.81,
      ),
      httpClient: MockClient((_) async => successResponse([])),
    );

    await controller.load();

    expect(controller.state, NearbyHotelsState.empty);
    expect(controller.hotels, isEmpty);
  });

  test('permission denied shows a Nearby Hotels-specific state, not a generic error', () async {
    final controller = _controllerWith(
      location: const LocationResult(outcome: LocationOutcome.permissionDenied),
      httpClient: MockClient((_) async => successResponse([])),
    );

    await controller.load();

    expect(controller.state, NearbyHotelsState.permissionDenied);
    expect(controller.hotels, isEmpty);
  });

  test('permission denied forever is distinguished from a one-time denial', () async {
    final controller = _controllerWith(
      location: const LocationResult(
        outcome: LocationOutcome.permissionDeniedForever,
      ),
      httpClient: MockClient((_) async => successResponse([])),
    );

    await controller.load();

    expect(controller.state, NearbyHotelsState.permissionDeniedForever);
  });

  test('location services disabled is distinguished from permission denial', () async {
    final controller = _controllerWith(
      location: const LocationResult(outcome: LocationOutcome.serviceDisabled),
      httpClient: MockClient((_) async => successResponse([])),
    );

    await controller.load();

    expect(controller.state, NearbyHotelsState.serviceDisabled);
  });

  test('a backend/network failure after a granted location is a retryable error', () async {
    final controller = _controllerWith(
      location: const LocationResult(
        outcome: LocationOutcome.granted,
        latitude: -1.28,
        longitude: 36.81,
      ),
      httpClient: MockClient(
        (_) async => errorResponse('INTERNAL_SERVER_ERROR', 'failed', 500),
      ),
    );

    await controller.load();

    expect(controller.state, NearbyHotelsState.error);
    expect(controller.errorMessage, isNotNull);
  });

  test('loading state is set while locating, before the location result resolves', () async {
    final controller = _controllerWith(
      location: const LocationResult(outcome: LocationOutcome.granted, latitude: 0, longitude: 0),
      httpClient: MockClient((_) async => successResponse([])),
    );

    expect(controller.state, NearbyHotelsState.locating);
    final future = controller.load();
    await future;
    expect(controller.state, NearbyHotelsState.empty);
  });
}
