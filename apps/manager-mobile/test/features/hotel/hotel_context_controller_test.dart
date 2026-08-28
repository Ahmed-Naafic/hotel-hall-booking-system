import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';

import '../../test_support.dart';

Map<String, dynamic> _hotel({String status = 'REGISTERED', String id = 'h1'}) => {
      'id': id,
      'registeredByUserId': 'u1',
      'status': status,
      'profileData': null,
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

HotelContextController _controller({
  required InMemoryTokenStorage storage,
  required Future<http.Response> Function(http.Request) handler,
}) {
  final client = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return HotelContextController(repository: HotelRepository(client), storage: storage);
}

void main() {
  group('HotelContextController.load', () {
    test('no cached hotel id -> status none, no API call made', () async {
      var called = false;
      final controller = _controller(
        storage: InMemoryTokenStorage(),
        handler: (r) async {
          called = true;
          return successResponse({});
        },
      );

      await controller.load();

      expect(controller.status, HotelContextStatus.none);
      expect(called, false);
    });

    test('a cached hotel id resolves to status ready with the real Hotel status', () async {
      final storage = InMemoryTokenStorage();
      await storage.write('hh_hotel_id', 'h1');
      final controller = _controller(
        storage: storage,
        handler: (r) async {
          expect(r.url.path, '/api/v1/hotels/h1');
          return successResponse(_hotel(status: 'APPROVED_ACTIVE'));
        },
      );

      await controller.load();

      expect(controller.status, HotelContextStatus.ready);
      expect(controller.hotel?.status, 'APPROVED_ACTIVE');
    });

    test('a stale cached id (404) clears itself back to status none', () async {
      final storage = InMemoryTokenStorage();
      await storage.write('hh_hotel_id', 'gone');
      final controller = _controller(
        storage: storage,
        handler: (r) async => errorResponse('NOT_FOUND', 'Hotel not found.', 404),
      );

      await controller.load();

      expect(controller.status, HotelContextStatus.none);
      expect(await storage.read('hh_hotel_id'), isNull);
    });
  });

  group('HotelContextController.createHotel', () {
    test('success caches the returned id and reaches status ready', () async {
      final storage = InMemoryTokenStorage();
      final controller = _controller(
        storage: storage,
        handler: (r) async {
          expect(r.method, 'POST');
          expect(r.url.path, '/api/v1/hotels');
          return successResponse(_hotel(id: 'new-hotel'), status: 201);
        },
      );

      final ok = await controller.createHotel();

      expect(ok, true);
      expect(controller.status, HotelContextStatus.ready);
      expect(controller.hotel?.id, 'new-hotel');
      expect(await storage.read('hh_hotel_id'), 'new-hotel');
    });

    test('an API error surfaces the server message and stays at status none', () async {
      final controller = _controller(
        storage: InMemoryTokenStorage(),
        handler: (r) async => errorResponse('AUTHENTICATION_ERROR', 'Missing, invalid, or expired access token.', 401),
      );

      final ok = await controller.createHotel();

      expect(ok, false);
      expect(controller.status, HotelContextStatus.none);
      expect(controller.errorMessage, 'Missing, invalid, or expired access token.');
    });
  });

  group('HotelContextController.submitApplication', () {
    test('success re-fetches the Hotel — status reflects the backend, not a local guess', () async {
      final storage = InMemoryTokenStorage();
      await storage.write('hh_hotel_id', 'h1');
      var postCalled = false;
      final controller = _controller(
        storage: storage,
        handler: (r) async {
          if (r.method == 'POST') {
            postCalled = true;
            expect(r.url.path, '/api/v1/hotels/h1/applications');
            return successResponse({
              'id': 'app1',
              'hotelId': 'h1',
              'status': 'OPEN',
              'decidedByUserId': null,
              'decidedAt': null,
              'submittedAt': '2026-08-26T00:00:00.000Z',
            }, status: 201);
          }
          return successResponse(_hotel(status: postCalled ? 'UNDER_REVIEW' : 'PROFILE_COMPLETE'));
        },
      );
      await controller.load();
      expect(controller.hotel?.status, 'PROFILE_COMPLETE');

      final ok = await controller.submitApplication();

      expect(ok, true);
      expect(postCalled, true);
      expect(controller.hotel?.status, 'UNDER_REVIEW');
      expect(controller.isSubmittingApplication, false);
    });

    test('a 409 conflict (already under review) surfaces the server message', () async {
      final storage = InMemoryTokenStorage();
      await storage.write('hh_hotel_id', 'h1');
      final controller = _controller(
        storage: storage,
        handler: (r) async {
          if (r.method == 'GET') return successResponse(_hotel(status: 'UNDER_REVIEW'));
          return errorResponse('CONFLICT', 'This Hotel already has an application under review.', 409);
        },
      );
      await controller.load();

      final ok = await controller.submitApplication();

      expect(ok, false);
      expect(controller.errorMessage, 'This Hotel already has an application under review.');
      expect(controller.isSubmittingApplication, false);
      // The Hotel already loaded (UNDER_REVIEW) is left as-is — no local
      // guess overwrites it on failure.
      expect(controller.hotel?.status, 'UNDER_REVIEW');
    });

    test('no Hotel resolved yet -> no-op, returns false', () async {
      final controller = _controller(
        storage: InMemoryTokenStorage(),
        handler: (r) async => throw StateError('no request should be made'),
      );

      final ok = await controller.submitApplication();

      expect(ok, false);
    });
  });
}
