import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/halls/application/hall_list_controller.dart';
import 'package:manager_mobile/features/halls/data/hall_repository.dart';

import '../../test_support.dart';

Map<String, dynamic> _hall({String id = 'hall-1'}) => {
      'id': id,
      'hotelId': 'h1',
      'profileData': {'name': 'The Ivory Room'},
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

/// Matches the real backend envelope exactly
/// (`hall.controller.js#listHallsForHotel`): `data` is the Hall array
/// itself, `pagination` is a sibling field, never nested inside `data`.
http.Response _pageResponse(
  List<Map<String, dynamic>> halls, {
  required int page,
  required int total,
  required bool hasNext,
  required bool hasPrevious,
  int limit = 20,
}) =>
    http.Response(
      jsonEncode({
        'status': 'success',
        'message': 'Halls retrieved successfully.',
        'data': halls,
        'pagination': {'page': page, 'limit': limit, 'total': total, 'totalPages': (total / limit).ceil(), 'hasNext': hasNext, 'hasPrevious': hasPrevious},
      }),
      200,
    );

HallListController _controller({required Future<http.Response> Function(http.Request) handler}) {
  final client = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return HallListController(repository: HallRepository(client), hotelId: 'h1');
}

void main() {
  group('HallListController.load', () {
    test('an empty result reaches status empty', () async {
      final controller = _controller(handler: (r) async {
        expect(r.url.path, '/api/v1/hotels/h1/halls');
        return _pageResponse([], page: 1, total: 0, hasNext: false, hasPrevious: false);
      });

      await controller.load();

      expect(controller.status, HallListStatus.empty);
      expect(controller.halls, isEmpty);
    });

    test('a non-empty result reaches status ready with the Halls parsed', () async {
      final controller = _controller(
        handler: (r) async => _pageResponse([_hall()], page: 1, total: 1, hasNext: false, hasPrevious: false),
      );

      await controller.load();

      expect(controller.status, HallListStatus.ready);
      expect(controller.halls, hasLength(1));
      expect(controller.halls.first.displayTitle, 'The Ivory Room');
    });

    test('an API error reaches status error with the server message', () async {
      final controller = _controller(handler: (r) async => errorResponse('NOT_FOUND', "hotelId doesn't exist.", 404));

      await controller.load();

      expect(controller.status, HallListStatus.error);
      expect(controller.errorMessage, "hotelId doesn't exist.");
    });

    test('a 401/403 response is surfaced through the same error path, never silently ignored', () async {
      final controller = _controller(
        handler: (r) async => errorResponse('AUTHENTICATION_ERROR', 'Missing, invalid, or expired access token.', 401),
      );

      await controller.load();

      expect(controller.status, HallListStatus.error);
      expect(controller.errorMessage, isNotNull);
    });
  });

  group('HallListController.loadMore', () {
    test('appends the next page and updates hasNext', () async {
      // Branches on the actual query, not call order: `load()` now also
      // fires its own (fire-and-forget) `limit: 1` chip-count requests
      // alongside the real page fetch, so a naive "2nd call = page 2"
      // assumption would race against them.
      final controller = _controller(handler: (r) async {
        if (r.url.queryParameters['limit'] == '1') {
          return _pageResponse([], page: 1, total: 0, hasNext: false, hasPrevious: false, limit: 1);
        }
        if (r.url.queryParameters['page'] == '2') {
          return _pageResponse([_hall(id: 'hall-2')], page: 2, total: 2, hasNext: false, hasPrevious: true);
        }
        return _pageResponse([_hall(id: 'hall-1')], page: 1, total: 2, hasNext: true, hasPrevious: false);
      });

      await controller.load();
      expect(controller.hasNext, true);

      await controller.loadMore();

      expect(controller.halls, hasLength(2));
      expect(controller.hasNext, false);
    });
  });

  group('HallListController — search and status filter', () {
    test('setSearch is debounced — no request until it settles, then sends `search`', () async {
      final requests = <Uri>[];
      final controller = _controller(handler: (r) async {
        requests.add(r.url);
        return _pageResponse([], page: 1, total: 0, hasNext: false, hasPrevious: false);
      });

      controller.setSearch('b');
      controller.setSearch('ba');
      controller.setSearch('ball');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(requests, isEmpty, reason: 'still within the debounce window');

      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(requests.any((u) => u.queryParameters['search'] == 'ball'), true);
    });

    test('setStatusFilter reloads immediately (never debounced) with `status`', () async {
      final requests = <Uri>[];
      final controller = _controller(handler: (r) async {
        requests.add(r.url);
        return _pageResponse([], page: 1, total: 0, hasNext: false, hasPrevious: false);
      });

      controller.setStatusFilter('active');
      await Future<void>.delayed(Duration.zero);

      expect(requests.any((u) => u.queryParameters['status'] == 'active'), true);
    });

    test('loadCounts derives inactiveCount from allCount - activeCount, from two limit:1 calls', () async {
      final controller = _controller(handler: (r) async {
        if (r.url.queryParameters['status'] == 'active') {
          return _pageResponse([], page: 1, total: 6, hasNext: false, hasPrevious: false, limit: 1);
        }
        return _pageResponse([], page: 1, total: 8, hasNext: false, hasPrevious: false, limit: 1);
      });

      await controller.loadCounts();

      expect(controller.allCount, 8);
      expect(controller.activeCount, 6);
      expect(controller.inactiveCount, 2);
    });
  });

  group('HallListController.setHallActive', () {
    test('PATCHes isActive then reloads the list', () async {
      var patchedActive = <String, dynamic>{};
      final controller = _controller(handler: (r) async {
        if (r.method == 'PATCH') {
          patchedActive = jsonDecode(r.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'status': 'success', 'message': 'ok', 'data': _hall()}),
            200,
          );
        }
        return _pageResponse([_hall()], page: 1, total: 1, hasNext: false, hasPrevious: false);
      });
      await controller.load();

      await controller.setHallActive(controller.halls.first, false);

      expect(patchedActive, {'isActive': false});
      expect(controller.status, HallListStatus.ready);
    });
  });
}
