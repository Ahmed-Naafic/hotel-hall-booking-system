import 'dart:convert';

import 'package:customer_mobile/features/discovery/application/all_halls_controller.dart';
import 'package:customer_mobile/features/discovery/data/discovery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _paginatedResponse(
  List<Map<String, dynamic>> data, {
  required bool hasNext,
  String? nextCursor,
}) => http.Response(
  jsonEncode({
    'status': 'success',
    'message': 'ok',
    'data': data,
    'pagination': {'limit': 20, 'hasNext': hasNext, 'nextCursor': nextCursor},
  }),
  200,
);

Map<String, dynamic> _hallJson(String id, {String hotelName = 'Test Hotel'}) => {
  'id': id,
  'hotelId': 'hotel-1',
  'profileData': {'name': 'Hall $id', 'capacity': 100},
  'photos': [],
  'hotel': {'id': 'hotel-1', 'name': hotelName},
};

void main() {
  test('loads the first page', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => _paginatedResponse([_hallJson('h1'), _hallJson('h2')], hasNext: false),
      ),
      baseUrl: 'http://test/api/v1',
    );
    final controller = AllHallsController(DiscoveryRepository(client));

    await controller.load();

    expect(controller.state, AllHallsState.loaded);
    expect(controller.halls.map((h) => h.id), ['h1', 'h2']);
    expect(controller.hasMore, false);
  });

  test('an empty first page is an empty state', () async {
    final client = ApiClient(
      httpClient: MockClient((_) async => _paginatedResponse([], hasNext: false)),
      baseUrl: 'http://test/api/v1',
    );
    final controller = AllHallsController(DiscoveryRepository(client));

    await controller.load();

    expect(controller.state, AllHallsState.empty);
  });

  test('loadMore appends the next page using the returned cursor', () async {
    final requestedCursors = <String?>[];
    final client = ApiClient(
      httpClient: MockClient((request) async {
        requestedCursors.add(request.url.queryParameters['cursor']);
        if (request.url.queryParameters['cursor'] == null) {
          return _paginatedResponse([_hallJson('h1')], hasNext: true, nextCursor: 'h1');
        }
        return _paginatedResponse([_hallJson('h2')], hasNext: false);
      }),
      baseUrl: 'http://test/api/v1',
    );
    final controller = AllHallsController(DiscoveryRepository(client));

    await controller.load();
    expect(controller.hasMore, true);
    expect(controller.halls.map((h) => h.id), ['h1']);

    await controller.loadMore();

    expect(controller.halls.map((h) => h.id), ['h1', 'h2']);
    expect(controller.hasMore, false);
    expect(requestedCursors, [null, 'h1']);
  });

  test('loadMore does nothing once hasMore is false', () async {
    var requestCount = 0;
    final client = ApiClient(
      httpClient: MockClient((_) async {
        requestCount++;
        return _paginatedResponse([_hallJson('h1')], hasNext: false);
      }),
      baseUrl: 'http://test/api/v1',
    );
    final controller = AllHallsController(DiscoveryRepository(client));

    await controller.load();
    expect(requestCount, 1);

    await controller.loadMore();
    expect(requestCount, 1, reason: 'loadMore must not fetch when hasMore is false');
  });

  test('a backend/network failure on the first load is a retryable error', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 'error',
            'error': 'INTERNAL_SERVER_ERROR',
            'message': 'failed',
            'timestamp': '',
            'requestId': 'r',
          }),
          500,
        ),
      ),
      baseUrl: 'http://test/api/v1',
    );
    final controller = AllHallsController(DiscoveryRepository(client));

    await controller.load();

    expect(controller.state, AllHallsState.error);
    expect(controller.errorMessage, isNotNull);
  });
}
