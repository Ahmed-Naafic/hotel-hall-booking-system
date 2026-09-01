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

/// `GET /hotels/me`'s actual response shape (`hotelController.getMyHotel` —
/// `MyHotelSnapshot.fromJson` on the client side): the Hotel keyed under
/// `hotel` (or `null` if the Manager has none yet) alongside its
/// `latestApplication`, never a bare Hotel object.
Map<String, dynamic> _myHotelResponse({Map<String, dynamic>? hotel}) =>
    {'hotel': hotel, 'latestApplication': null};

HotelContextController _controller({
  required InMemoryTokenStorage storage,
  required Future<http.Response> Function(http.Request) handler,
}) {
  final client = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return HotelContextController(repository: HotelRepository(client), storage: storage);
}

void main() {
  group('HotelContextController.load', () {
    test('always resolves via GET /hotels/me, regardless of any local cache', () async {
      var callCount = 0;
      final controller = _controller(
        storage: InMemoryTokenStorage(),
        handler: (r) async {
          callCount++;
          expect(r.method, 'GET');
          expect(r.url.path, '/api/v1/hotels/me');
          return successResponse(_myHotelResponse());
        },
      );

      await controller.load();

      expect(callCount, 1);
    });

    test('no Hotel yet (hotel: null) -> status none', () async {
      final controller = _controller(
        storage: InMemoryTokenStorage(),
        handler: (r) async => successResponse(_myHotelResponse()),
      );

      await controller.load();

      expect(controller.status, HotelContextStatus.none);
      expect(controller.hotel, isNull);
    });

    test('a Hotel is returned -> status ready with the real Hotel status, cached locally', () async {
      final storage = InMemoryTokenStorage();
      final controller = _controller(
        storage: storage,
        handler: (r) async => successResponse(
          _myHotelResponse(hotel: _hotel(status: 'APPROVED_ACTIVE')),
        ),
      );

      await controller.load();

      expect(controller.status, HotelContextStatus.ready);
      expect(controller.hotel?.status, 'APPROVED_ACTIVE');
      // The local id cache remains a convenience (doc comment on
      // HotelContextController) — written on every successful resolution,
      // even though load() itself never reads it back to decide what to
      // fetch.
      expect(await storage.read('hh_hotel_id'), 'h1');
    });

    test('an API error (e.g. account/session trouble) surfaces as status error, not none', () async {
      final controller = _controller(
        storage: InMemoryTokenStorage(),
        handler: (r) async => errorResponse('AUTHENTICATION_ERROR', 'Missing, invalid, or expired access token.', 401),
      );

      await controller.load();

      expect(controller.status, HotelContextStatus.error);
      expect(controller.errorMessage, 'Missing, invalid, or expired access token.');
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
          return successResponse(_myHotelResponse(
            hotel: _hotel(status: postCalled ? 'UNDER_REVIEW' : 'PROFILE_COMPLETE'),
          ));
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
      final controller = _controller(
        storage: storage,
        handler: (r) async {
          if (r.method == 'GET') {
            return successResponse(_myHotelResponse(hotel: _hotel(status: 'UNDER_REVIEW')));
          }
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
