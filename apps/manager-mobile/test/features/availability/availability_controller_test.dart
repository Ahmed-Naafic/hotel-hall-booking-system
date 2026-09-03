import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/availability/application/availability_controller.dart';
import 'package:manager_mobile/features/availability/data/availability_models.dart';
import 'package:manager_mobile/features/availability/data/availability_repository.dart';

Map<String, dynamic> _blockJson({
  String id = 'block-1',
  String startsAt = '2026-09-10T07:00:00.000Z',
  String endsAt = '2026-09-10T11:00:00.000Z',
  String? reason = 'Maintenance',
}) => {
      'id': id,
      'hallId': 'hall-1',
      'startsAt': startsAt,
      'endsAt': endsAt,
      'reason': reason,
      'createdByUserId': 'u1',
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

http.Response _listResponse(List<Map<String, dynamic>> blocks) => http.Response(
      jsonEncode({'status': 'success', 'message': 'ok', 'data': blocks}),
      200,
    );

http.Response _errorResponse(String error, String message, int status) => http.Response(
      jsonEncode({'status': 'error', 'error': error, 'message': message, 'timestamp': '', 'requestId': 'r'}),
      status,
    );

AvailabilityController _controller(Future<http.Response> Function(http.Request) handler) {
  final client = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return AvailabilityController(
    repository: AvailabilityRepository(client),
    hotelId: 'h1',
    hallId: 'hall-1',
    initialDate: DateTime(2026, 9, 10),
  );
}

void main() {
  test('load() with no blocks reaches status empty', () async {
    final controller = _controller((r) async => _listResponse([]));
    await controller.load();

    expect(controller.status, AvailabilityStatus.empty);
    expect(controller.blocks, isEmpty);
  });

  test('load() with blocks reaches status ready, preserving the server\'s own order', () async {
    // The backend already guarantees `ORDER BY starts_at ASC`
    // (`availability.repository.js#listForHallInRange`) — `load()` trusts
    // that order rather than re-sorting, the same way `HallListController`
    // trusts its own list endpoint's order.
    final controller = _controller(
      (r) async => _listResponse([
        _blockJson(id: 'b1', startsAt: '2026-09-10T07:00:00.000Z', endsAt: '2026-09-10T09:00:00.000Z'),
        _blockJson(id: 'b2', startsAt: '2026-09-10T11:00:00.000Z', endsAt: '2026-09-10T13:00:00.000Z'),
      ]),
    );
    await controller.load();

    expect(controller.status, AvailabilityStatus.ready);
    expect(controller.blocks.map((b) => b.id).toList(), ['b1', 'b2']);
  });

  test('upsert() keeps the list chronologically ordered after inserting a block earlier in the day', () async {
    final controller = _controller(
      (r) async => _listResponse([
        _blockJson(id: 'b2', startsAt: '2026-09-10T11:00:00.000Z', endsAt: '2026-09-10T13:00:00.000Z'),
      ]),
    );
    await controller.load();

    await controller.upsert(AvailabilityBlock.fromJson(
      _blockJson(id: 'b1', startsAt: '2026-09-10T07:00:00.000Z', endsAt: '2026-09-10T09:00:00.000Z'),
    ));

    expect(controller.blocks.map((b) => b.id).toList(), ['b1', 'b2']);
  });

  test(
    'upsert() with a block on a different Mogadishu date switches the view to that date instead of '
    'showing it under the currently-viewed day',
    () async {
      var requestedDates = <String>[];
      final controller = _controller((r) async {
        requestedDates.add(r.url.queryParameters['date']!);
        // The day-10 view; the day-17 reload (triggered by upsert) returns
        // the block that "belongs" there.
        if (r.url.queryParameters['date'] == '2026-09-17') {
          return _listResponse([
            _blockJson(id: 'future', startsAt: '2026-09-17T07:00:00.000Z', endsAt: '2026-09-17T09:00:00.000Z'),
          ]);
        }
        return _listResponse([]);
      });
      await controller.load(); // viewing 2026-09-10, currently empty
      expect(controller.blocks, isEmpty);

      // Created while viewing 2026-09-10, but its own period is on 2026-09-17.
      await controller.upsert(AvailabilityBlock.fromJson(
        _blockJson(id: 'future', startsAt: '2026-09-17T07:00:00.000Z', endsAt: '2026-09-17T09:00:00.000Z'),
      ));

      // The view switched to the block's own date and reloaded
      // authoritatively — it never appears "under" 2026-09-10.
      expect(controller.selectedDate, DateTime(2026, 9, 17));
      expect(requestedDates, contains('2026-09-17'));
      expect(controller.blocks.single.id, 'future');
    },
  );

  test('an API error reaches status error with the server message', () async {
    final controller = _controller((r) async => _errorResponse('NOT_FOUND', 'Hall not found.', 404));
    await controller.load();

    expect(controller.status, AvailabilityStatus.error);
    expect(controller.errorMessage, 'Hall not found.');
  });

  test('changeDate() reloads for the new date', () async {
    var lastQuery = '';
    final controller = _controller((r) async {
      lastQuery = r.url.query;
      return _listResponse([]);
    });
    await controller.load();
    await controller.changeDate(DateTime(2026, 9, 11));

    expect(lastQuery, 'date=2026-09-11');
  });

  test('upsert() adds a new block locally without a network call', () async {
    final controller = _controller((r) async => _listResponse([]));
    await controller.load();
    expect(controller.status, AvailabilityStatus.empty);

    await controller.upsert(AvailabilityBlock.fromJson(_blockJson()));

    expect(controller.status, AvailabilityStatus.ready);
    expect(controller.blocks.single.id, 'block-1');
  });

  test('upsert() with an existing id replaces it in place', () async {
    final controller = _controller((r) async => _listResponse([_blockJson()]));
    await controller.load();

    await controller.upsert(AvailabilityBlock.fromJson(_blockJson(reason: 'Renamed')));

    expect(controller.blocks.single.reason, 'Renamed');
  });

  test('deleteBlock() calls DELETE and removes the block locally', () async {
    var deleteCalled = false;
    final controller = _controller((r) async {
      if (r.method == 'DELETE') {
        deleteCalled = true;
        return http.Response('', 204);
      }
      return _listResponse([_blockJson()]);
    });
    await controller.load();
    expect(controller.blocks, isNotEmpty);

    await controller.deleteBlock('block-1');

    expect(deleteCalled, true);
    expect(controller.blocks, isEmpty);
    expect(controller.status, AvailabilityStatus.empty);
  });
}
