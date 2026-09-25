import 'dart:convert';

import 'package:customer_mobile/core/location_service.dart';
import 'package:customer_mobile/features/discovery/application/all_halls_controller.dart';
import 'package:customer_mobile/features/discovery/application/discovery_controller.dart';
import 'package:customer_mobile/features/discovery/application/large_halls_controller.dart';
import 'package:customer_mobile/features/discovery/application/nearby_hotels_controller.dart';
import 'package:customer_mobile/features/discovery/application/popular_hotels_controller.dart';
import 'package:customer_mobile/features/discovery/data/discovery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Out-of-order responses, which is the shape the Discover search bug
/// actually had: the request for the newest query was sent, but an older
/// one answered later and overwrote it, so the tab sat there showing the
/// full unfiltered list.
///
/// A plain `MockClient` answers in the order it was called, so it can never
/// reproduce this — the handler below deliberately answers *slower for
/// older queries*, inverting completion order. Each controller must still
/// end on the newest query's results.

// ---------------------------------------------------------------------------
// A backend that answers older queries last
// ---------------------------------------------------------------------------

/// Longest first: a query typed earlier in this list resolves later, so the
/// natural "last response wins" behaviour would land on the wrong one.
const _latencyByQuery = {
  'hotel': Duration(milliseconds: 120),
  'guu': Duration(milliseconds: 80),
  'guuleed': Duration(milliseconds: 20),
};

http.Response _envelope(dynamic data, {Map<String, dynamic>? pagination}) =>
    http.Response(
      jsonEncode({
        'status': 'success',
        'message': 'ok',
        'data': data,
        'pagination': ?pagination,
      }),
      200,
    );

Map<String, dynamic> _hotelJson(String id, {int bookingCount = 1, double? distanceKm}) => {
  'id': id,
  'profileData': {'name': 'Hotel $id'},
  'logo': null,
  'photos': [],
  'bookingCount': bookingCount,
  'distanceKm': ?distanceKm,
};

Map<String, dynamic> _hallJson(String id) => {
  'id': id,
  'hotelId': 'hotel-1',
  'profileData': {'name': 'Hall $id', 'capacity': 100},
  'photos': [],
  'hotel': {'id': 'hotel-1', 'name': 'Parent Property'},
};

/// Answers every discovery endpoint with a single record named after the
/// query that asked for it, after that query's own latency — so the result
/// a controller ends up holding names the query it really came from.
MockClient _slowestFirstClient({List<String>? log}) => MockClient((request) async {
  final search = request.url.queryParameters['search'] ?? '';
  log?.add(search);
  await Future<void>.delayed(_latencyByQuery[search] ?? Duration.zero);

  final path = request.url.path;
  if (path.endsWith('/halls/large-capacity') || path.endsWith('/halls')) {
    final data = [_hallJson('for-$search')];
    return path.endsWith('/halls')
        ? _envelope(data, pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null})
        : _envelope(data);
  }
  if (path.endsWith('/hotels/public/nearby')) {
    return _envelope([_hotelJson('for-$search', distanceKm: 1.0)]);
  }
  if (path.endsWith('/hotels/public/popular')) {
    return _envelope([_hotelJson('for-$search')]);
  }
  // /hotels/public
  return _envelope(
    [_hotelJson('for-$search')],
    pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
  );
});

DiscoveryRepository _repositoryWith(http.Client client) =>
    DiscoveryRepository(ApiClient(httpClient: client, baseUrl: 'http://test/api/v1'));

class _FakeLocationService extends LocationService {
  _FakeLocationService(this.result);
  final LocationResult result;
  int locateCount = 0;

  @override
  Future<LocationResult> getCurrentLocation() async {
    locateCount++;
    return result;
  }
}

const _granted = LocationResult(
  outcome: LocationOutcome.granted,
  latitude: 2.04,
  longitude: 45.34,
);

/// Types three queries in a row without waiting for any of them, the way a
/// customer refining a search does once each pause crosses the debounce.
Future<void> _typeThree(Future<void> Function(String) search) =>
    Future.wait([search('hotel'), search('guu'), search('guuleed')]);

void main() {
  group('an older response can never overwrite a newer query', () {
    test('Large Halls', () async {
      final controller = LargeHallsController(_repositoryWith(_slowestFirstClient()));

      await _typeThree(controller.search);

      expect(controller.halls.single.id, 'for-guuleed');
      expect(controller.state, LargeHallsState.loaded);
    });

    test('All Halls', () async {
      final controller = AllHallsController(_repositoryWith(_slowestFirstClient()));

      await _typeThree(controller.search);

      expect(controller.halls.single.id, 'for-guuleed');
      expect(controller.state, AllHallsState.loaded);
    });

    test('Popular', () async {
      final controller = PopularHotelsController(_repositoryWith(_slowestFirstClient()));

      await _typeThree(controller.search);

      expect(controller.hotels.single.id, 'for-guuleed');
      expect(controller.state, PopularHotelsState.loaded);
    });

    test('All Hotels', () async {
      final controller = DiscoveryController(_repositoryWith(_slowestFirstClient()));

      await _typeThree(controller.search);

      expect(controller.hotels.single.id, 'for-guuleed');
      expect(controller.isSearchActive, isTrue);
      expect(controller.isLoading, isFalse);
    });

    test('Near You', () async {
      final controller = NearbyHotelsController(
        repository: _repositoryWith(_slowestFirstClient()),
        locationService: _FakeLocationService(_granted),
      );
      await controller.load();

      await _typeThree(controller.search);

      expect(controller.hotels.single.id, 'for-guuleed');
      expect(controller.state, NearbyHotelsState.loaded);
    });
  });

  group('clearing the search cannot be overwritten either', () {
    test('a slow in-flight search does not land after the box was cleared', () async {
      final controller = LargeHallsController(
        _repositoryWith(
          MockClient((request) async {
            final search = request.url.queryParameters['search'] ?? '';
            // The search is slow; clearing it answers immediately.
            await Future<void>.delayed(
              search.isEmpty ? Duration.zero : const Duration(milliseconds: 100),
            );
            return _envelope([_hallJson('for-$search')]);
          }),
        ),
      );

      await Future.wait([controller.search('guuleed'), controller.search('')]);

      expect(controller.halls.single.id, 'for-');
    });

    test('All Hotels returns to the unsearched browse, not the stale search', () async {
      final controller = DiscoveryController(
        _repositoryWith(
          MockClient((request) async {
            final search = request.url.queryParameters['search'];
            await Future<void>.delayed(
              search == null ? Duration.zero : const Duration(milliseconds: 100),
            );
            return _envelope(
              [_hotelJson(search == null ? 'browse' : 'for-$search')],
              pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
            );
          }),
        ),
      );

      await Future.wait([controller.search('guuleed'), controller.search('')]);

      expect(controller.hotels.single.id, 'browse');
      expect(controller.isSearchActive, isFalse);
    });
  });

  group('pagination and search together', () {
    /// Two pages of Halls per query, so `loadMore` has something to append.
    MockClient pagedClient({List<Uri>? log}) => MockClient((request) async {
      log?.add(request.url);
      final search = request.url.queryParameters['search'] ?? '';
      final cursor = request.url.queryParameters['cursor'];
      if (cursor == null) {
        return _envelope(
          [_hallJson('$search-p1')],
          pagination: {'limit': 20, 'hasNext': true, 'nextCursor': '$search-p1'},
        );
      }
      return _envelope(
        [_hallJson('$search-p2')],
        pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
      );
    });

    test('the next page keeps the active query and appends to it', () async {
      final log = <Uri>[];
      final controller = AllHallsController(_repositoryWith(pagedClient(log: log)));

      await controller.search('guuleed');
      expect(controller.halls.map((hall) => hall.id), ['guuleed-p1']);
      expect(controller.hasMore, isTrue);

      await controller.loadMore();

      expect(controller.halls.map((hall) => hall.id), ['guuleed-p1', 'guuleed-p2']);
      expect(controller.hasMore, isFalse);
      // The second page was asked for with both the cursor and the query —
      // paging a search must not silently page the unsearched list.
      expect(log.last.queryParameters['search'], 'guuleed');
      expect(log.last.queryParameters['cursor'], 'guuleed-p1');
    });

    test('a page that arrives after the query changed is dropped, not appended', () async {
      final controller = AllHallsController(
        _repositoryWith(
          MockClient((request) async {
            final search = request.url.queryParameters['search'] ?? '';
            final cursor = request.url.queryParameters['cursor'];
            if (cursor != null) {
              // The next page of the *old* query is the slowest thing here.
              await Future<void>.delayed(const Duration(milliseconds: 120));
              return _envelope(
                [_hallJson('$search-p2')],
                pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
              );
            }
            return _envelope(
              [_hallJson('$search-p1')],
              pagination: {'limit': 20, 'hasNext': true, 'nextCursor': '$search-p1'},
            );
          }),
        ),
      );

      await controller.search('guu');
      // Scrolled to the bottom, then immediately refined the query.
      await Future.wait([controller.loadMore(), controller.search('guuleed')]);

      expect(controller.halls.map((hall) => hall.id), ['guuleed-p1']);
      // The dropped page must not leave paging jammed.
      expect(controller.isLoadingMore, isFalse);
      expect(controller.hasMore, isTrue);
    });

    test('All Hotels drops a search page belonging to an abandoned query', () async {
      final controller = DiscoveryController(
        _repositoryWith(
          MockClient((request) async {
            final search = request.url.queryParameters['search'] ?? '';
            final cursor = request.url.queryParameters['cursor'];
            if (cursor != null) {
              await Future<void>.delayed(const Duration(milliseconds: 120));
              return _envelope(
                [_hotelJson('$search-p2')],
                pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
              );
            }
            return _envelope(
              [_hotelJson('$search-p1')],
              pagination: {'limit': 20, 'hasNext': true, 'nextCursor': '$search-p1'},
            );
          }),
        ),
      );

      await controller.search('guu');
      await Future.wait([
        controller.loadMoreSearchResults(),
        controller.search('guuleed'),
      ]);

      expect(controller.hotels.map((hotel) => hotel.id), ['guuleed-p1']);
      expect(controller.isLoadingMoreSearchResults, isFalse);
    });
  });

  group('Near You and location availability', () {
    test('with a location, searching filters the nearby list', () async {
      final controller = NearbyHotelsController(
        repository: _repositoryWith(_slowestFirstClient()),
        locationService: _FakeLocationService(_granted),
      );
      await controller.load();

      await controller.search('guuleed');

      expect(controller.state, NearbyHotelsState.loaded);
      expect(controller.hotels.single.id, 'for-guuleed');
    });

    test('searching never asks for a location of its own', () async {
      final location = _FakeLocationService(_granted);
      final controller = NearbyHotelsController(
        repository: _repositoryWith(_slowestFirstClient()),
        locationService: location,
      );

      // Typed before the tab was ever opened — the search box must not be
      // what triggers a GPS permission prompt.
      await controller.search('guuleed');

      expect(location.locateCount, 0);
      expect(controller.hasLocation, isFalse);
      expect(controller.hotels, isEmpty);
      // The query is remembered rather than dropped.
      expect(controller.pendingSearch, 'guuleed');
    });

    test('a query typed before the tab was opened is applied by its first load', () async {
      final location = _FakeLocationService(_granted);
      final controller = NearbyHotelsController(
        repository: _repositoryWith(_slowestFirstClient()),
        locationService: location,
      );

      await controller.search('guuleed');
      // Opening the Near You tab is what locates.
      await controller.load();

      expect(location.locateCount, 1);
      expect(controller.state, NearbyHotelsState.loaded);
      expect(controller.hotels.single.id, 'for-guuleed');
    });

    test('the Discover screen seeds a controller built while a query is live', () async {
      // What `DiscoverScreen` does when Near You is opened with text already
      // in the box: construct with `initialSearch`, then load once.
      final controller = NearbyHotelsController(
        repository: _repositoryWith(_slowestFirstClient()),
        locationService: _FakeLocationService(_granted),
        initialSearch: 'guuleed',
      );

      await controller.load();

      expect(controller.hotels.single.id, 'for-guuleed');
    });

    test('without a location there are no results to leave stale', () async {
      final controller = NearbyHotelsController(
        repository: _repositoryWith(_slowestFirstClient()),
        locationService: _FakeLocationService(
          const LocationResult(outcome: LocationOutcome.permissionDenied),
        ),
      );

      await controller.load();
      await controller.search('guuleed');

      expect(controller.state, NearbyHotelsState.permissionDenied);
      expect(controller.hotels, isEmpty);
      expect(controller.hasLocation, isFalse);
    });

    test('losing location clears the previous results rather than keeping them behind the prompt', () async {
      final location = _FakeLocationService(_granted);
      final controller = NearbyHotelsController(
        repository: _repositoryWith(_slowestFirstClient()),
        locationService: location,
      );
      await controller.load();
      expect(controller.hotels, isNotEmpty);

      // Permission revoked between one look at the tab and the next.
      final denied = NearbyHotelsController(
        repository: _repositoryWith(_slowestFirstClient()),
        locationService: _FakeLocationService(
          const LocationResult(outcome: LocationOutcome.serviceDisabled),
        ),
      );
      await denied.load();

      expect(denied.state, NearbyHotelsState.serviceDisabled);
      expect(denied.hotels, isEmpty);
    });
  });

  group('an unchanged query is not refetched', () {
    test('Large Halls', () async {
      final queries = <String>[];
      final controller = LargeHallsController(
        _repositoryWith(_slowestFirstClient(log: queries)),
        initialSearch: 'guuleed',
      );

      await controller.load();
      // The Discover screen pushes the live query at every controller,
      // including one it just built with that same query.
      await controller.search('guuleed');

      expect(queries, ['guuleed']);
      expect(controller.halls.single.id, 'for-guuleed');
    });

    test('All Halls', () async {
      final queries = <String>[];
      final controller = AllHallsController(
        _repositoryWith(_slowestFirstClient(log: queries)),
        initialSearch: 'guuleed',
      );

      await controller.load();
      await controller.search('guuleed');

      expect(queries, ['guuleed']);
      expect(controller.halls.single.id, 'for-guuleed');
    });
  });
}
