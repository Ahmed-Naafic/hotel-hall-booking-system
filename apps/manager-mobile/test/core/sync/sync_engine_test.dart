import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/sync/sync_database.dart';
import 'package:manager_mobile/core/sync/sync_engine.dart';
import 'package:manager_mobile/core/sync/sync_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Local-first synchronization for Manager Mobile (ADR-0009), against a real
/// SQLite database — `sqflite_common_ffi` supplies the platform implementation
/// `flutter test` lacks — and a fake sync server that pages the way the real
/// endpoint does.
///
/// These assert the state of the replica after syncing, not that a request was
/// sent. The distinction matters: the Discover search bug earlier in this
/// project passed its tests for months because they only counted requests.

/// One page of the real `GET /sync/:collection` envelope.
http.Response _page({
  required List<Map<String, dynamic>> changed,
  List<String> deleted = const [],
  required bool hasNext,
  String? nextCursor,
  String scopeId = 'scope-a',
}) =>
    http.Response(
      jsonEncode({
        'status': 'success',
        'message': 'ok',
        'data': {
          'changed': changed,
          'deleted': deleted,
          'scopeId': scopeId,
          'serverTime': '2026-09-27T12:00:00.000Z',
        },
        'pagination': {'limit': 100, 'hasNext': hasNext, 'nextCursor': nextCursor},
      }),
      200,
    );

Map<String, dynamic> _hall(String id, String seq, {String hotelId = 'hotel-1', String name = 'Hall'}) => {
  'id': id,
  'syncSeq': seq,
  'hotelId': hotelId,
  'profileData': {'name': name, 'capacity': 100},
  'isActive': true,
};

Map<String, dynamic> _media(String id, String seq, {String hallId = 'hall-1'}) => {
  'id': id,
  'syncSeq': seq,
  'hallId': hallId,
  'type': 'PHOTO',
  'storagePath': 'halls/$hallId/$id.jpg',
};

/// Answers every collection with an empty page except the ones supplied.
MockClient _server(Map<String, List<http.Response>> pagesByCollection, {List<Uri>? log}) {
  final remaining = {
    for (final entry in pagesByCollection.entries) entry.key: [...entry.value],
  };
  return MockClient((request) async {
    log?.add(request.url);
    final collection = request.url.pathSegments.last;
    final queue = remaining[collection];
    if (queue == null || queue.isEmpty) {
      return _page(changed: [], hasNext: false, nextCursor: null);
    }
    return queue.removeAt(0);
  });
}

Future<({SyncEngine engine, SyncStore store, SyncDatabase db})> _harness(
  MockClient client,
) async {
  final db = await SyncDatabase.open(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
  final store = SyncStore(db);
  final engine = SyncEngine(
    apiClient: ApiClient(httpClient: client, baseUrl: 'http://test/api/v1'),
    store: store,
  );
  return (engine: engine, store: store, db: db);
}

void main() {
  setUpAll(sqfliteFfiInit);

  group('initial sync', () {
    test('stores every row and records the cursor', () async {
      final h = await _harness(_server({
        'hall': [
          _page(changed: [_hall('hall-1', '10'), _hall('hall-2', '11')], hasNext: false, nextCursor: '11'),
        ],
      }));

      final outcome = await h.engine.syncAll();

      expect(await h.store.count('hall'), 2);
      expect(await h.store.cursorFor('hall'), '11');
      expect(outcome.changed, 2);
      expect(outcome.wiped, isFalse);
      await h.db.close();
    });

    test('sends no `since` on the first request, and the cursor afterwards', () async {
      final log = <Uri>[];
      final h = await _harness(_server({
        'hall': [_page(changed: [_hall('hall-1', '10')], hasNext: false, nextCursor: '10')],
      }, log: log));

      await h.engine.syncAll();
      final first = log.firstWhere((uri) => uri.path.endsWith('/sync/hall'));
      expect(first.queryParameters.containsKey('since'), isFalse, reason: 'initial sync');

      log.clear();
      await h.engine.syncAll();
      final second = log.firstWhere((uri) => uri.path.endsWith('/sync/hall'));
      expect(second.queryParameters['since'], '10', reason: 'incremental sync resumes');
      await h.db.close();
    });

    test('an empty collection leaves an empty replica, not an error', () async {
      final h = await _harness(_server({}));

      final outcome = await h.engine.syncAll();

      expect(outcome.changed, 0);
      for (final collection in syncCollections) {
        expect(await h.store.count(collection), 0);
      }
      await h.db.close();
    });
  });

  group('pagination', () {
    test('follows the cursor across pages and stores every row once', () async {
      final h = await _harness(_server({
        'hall': [
          _page(changed: [_hall('hall-1', '10')], hasNext: true, nextCursor: '10'),
          _page(changed: [_hall('hall-2', '11')], hasNext: true, nextCursor: '11'),
          _page(changed: [_hall('hall-3', '12')], hasNext: false, nextCursor: '12'),
        ],
      }));

      final outcome = await h.engine.syncAll();

      expect(await h.store.count('hall'), 3);
      expect(outcome.pages, greaterThanOrEqualTo(3));
      expect(await h.store.cursorFor('hall'), '12');
      await h.db.close();
    });

    test('stops instead of looping when the server reports hasNext with no new cursor', () async {
      // A server contract violation. The engine must not spin: on a real device
      // that would drain battery and data indefinitely.
      final log = <Uri>[];
      final h = await _harness(MockClient((request) async {
        log.add(request.url);
        if (!request.url.path.endsWith('/sync/hall')) {
          return _page(changed: [], hasNext: false, nextCursor: null);
        }
        return _page(changed: [_hall('hall-1', '10')], hasNext: true, nextCursor: null);
      }));

      await h.engine.syncAll();

      // Counted per collection: every collection fetches at least one page, so
      // the cross-collection total says nothing about this one.
      expect(
        log.where((uri) => uri.path.endsWith('/sync/hall')).length,
        1,
        reason: 'one page for this collection, then stop',
      );
      await h.db.close();
    });

    test('stops when the cursor fails to advance', () async {
      final log = <Uri>[];
      final h = await _harness(MockClient((request) async {
        log.add(request.url);
        if (!request.url.path.endsWith('/sync/hall')) {
          return _page(changed: [], hasNext: false, nextCursor: null);
        }
        // Always the same cursor — an advancing `hasNext` that never moves.
        return _page(changed: [_hall('hall-1', '10')], hasNext: true, nextCursor: '10');
      }));

      await h.engine.syncAll();

      expect(
        log.where((uri) => uri.path.endsWith('/sync/hall')).length,
        lessThanOrEqualTo(2),
        reason: 'must detect the stuck cursor immediately, not page 500 times',
      );
      await h.db.close();
    });
  });

  group('incremental change', () {
    test('an updated row replaces the old one rather than duplicating it', () async {
      final h = await _harness(_server({
        'hall': [
          _page(changed: [_hall('hall-1', '10', name: 'Before')], hasNext: false, nextCursor: '10'),
          _page(changed: [_hall('hall-1', '20', name: 'After')], hasNext: false, nextCursor: '20'),
        ],
      }));

      await h.engine.syncAll();
      await h.engine.syncAll();

      expect(await h.store.count('hall'), 1, reason: 'same id, one row');
      final row = await h.store.byId('hall', 'hall-1');
      expect(row!['profileData']['name'], 'After');
      expect(row['syncSeq'], '20');
      await h.db.close();
    });

    test('a tombstone removes the row', () async {
      final h = await _harness(_server({
        'hallMedia': [
          _page(changed: [_media('media-1', '10')], hasNext: false, nextCursor: '10'),
          _page(changed: [], deleted: ['media-1'], hasNext: false, nextCursor: '20'),
        ],
      }));

      await h.engine.syncAll();
      expect(await h.store.count('hallMedia'), 1);

      await h.engine.syncAll();
      expect(await h.store.count('hallMedia'), 0, reason: 'the tombstone must delete it');
      expect(await h.store.byId('hallMedia', 'media-1'), isNull);
      await h.db.close();
    });

    test('repeating a sync with nothing new changes nothing', () async {
      final h = await _harness(_server({
        'hall': [_page(changed: [_hall('hall-1', '10')], hasNext: false, nextCursor: '10')],
      }));

      await h.engine.syncAll();
      final outcome = await h.engine.syncAll();

      expect(outcome.changed, 0);
      expect(await h.store.count('hall'), 1);
      expect(await h.store.cursorFor('hall'), '10');
      await h.db.close();
    });
  });

  group('scope invalidation', () {
    test('a changed scopeId discards the replica and rebuilds it', () async {
      // One scope for the whole first run, a different one for the whole second
      // — which is how a real permission change looks: every collection reports
      // the new scope, not just one.
      var scope = 'scope-a';
      final h = await _harness(MockClient((request) async {
        if (!request.url.path.endsWith('/sync/hall')) {
          return _page(changed: [], hasNext: false, nextCursor: null, scopeId: scope);
        }
        return _page(
          changed: [_hall(scope == 'scope-a' ? 'hall-old' : 'hall-new', scope == 'scope-a' ? '10' : '99')],
          hasNext: false,
          nextCursor: scope == 'scope-a' ? '10' : '99',
          scopeId: scope,
        );
      }));

      await h.engine.syncAll();
      expect(await h.store.byId('hall', 'hall-old'), isNotNull);
      expect(await h.store.scopeId(), 'scope-a');

      scope = 'scope-b';
      final outcome = await h.engine.syncAll();

      expect(outcome.wiped, isTrue);
      expect(
        await h.store.byId('hall', 'hall-old'),
        isNull,
        reason: 'rows synced under the old scope may no longer be this caller’s to hold',
      );
      expect(await h.store.byId('hall', 'hall-new'), isNotNull);
      expect(await h.store.scopeId(), 'scope-b');
      await h.db.close();
    });

    test('a wipe resets every cursor, not just the collection that noticed', () async {
      var scope = 'scope-a';
      final h = await _harness(MockClient((request) async {
        return _page(
          changed: request.url.path.endsWith('/sync/hall')
              ? [_hall('hall-1', scope == 'scope-a' ? '10' : '77')]
              : const [],
          hasNext: false,
          nextCursor: request.url.path.endsWith('/sync/hall') ? (scope == 'scope-a' ? '10' : '77') : null,
          scopeId: scope,
        );
      }));

      await h.engine.syncAll();
      expect(await h.store.cursorFor('hall'), '10');

      scope = 'scope-b';
      await h.engine.syncAll();

      // Cursors describe a set the caller was allowed to see under the old
      // scope; carrying one forward would resume mid-stream in a set that is no
      // longer theirs.
      expect(await h.store.cursorFor('hall'), '77');
      await h.db.close();
    });

    test('the first sync adopts whatever scope the server reports', () async {
      final h = await _harness(MockClient((request) async {
        return _page(
          changed: request.url.path.endsWith('/sync/hall') ? [_hall('hall-1', '10')] : const [],
          hasNext: false,
          nextCursor: request.url.path.endsWith('/sync/hall') ? '10' : null,
          scopeId: 'scope-z',
        );
      }));

      final outcome = await h.engine.syncAll();

      expect(outcome.wiped, isFalse, reason: 'nothing to discard on a first sync');
      expect(await h.store.scopeId(), 'scope-z');
      await h.db.close();
    });
  });

  group('reads by scope', () {
    test('rows are filtered in SQL by hotel and by hall', () async {
      final h = await _harness(_server({
        'hall': [
          _page(
            changed: [
              _hall('hall-1', '10', hotelId: 'hotel-1'),
              _hall('hall-2', '11', hotelId: 'hotel-2'),
            ],
            hasNext: false,
            nextCursor: '11',
          ),
        ],
        'hallMedia': [
          _page(
            changed: [_media('m-1', '12', hallId: 'hall-1'), _media('m-2', '13', hallId: 'hall-2')],
            hasNext: false,
            nextCursor: '13',
          ),
        ],
      }));

      await h.engine.syncAll();

      final ownHalls = await h.store.forHotel('hall', 'hotel-1');
      expect(ownHalls.map((row) => row['id']), ['hall-1']);

      final ownMedia = await h.store.forHall('hallMedia', 'hall-1');
      expect(ownMedia.map((row) => row['id']), ['m-1']);
      await h.db.close();
    });

    test('ordering is numeric on syncSeq, not lexicographic', () async {
      final h = await _harness(_server({
        'hall': [
          _page(
            changed: [_hall('hall-9', '9'), _hall('hall-10', '10')],
            hasNext: false,
            nextCursor: '10',
          ),
        ],
      }));

      await h.engine.syncAll();

      final rows = await h.store.all('hall');
      // Newest first: 10 before 9. A TEXT sort would put '9' first.
      expect(rows.map((row) => row['id']), ['hall-10', 'hall-9']);
      await h.db.close();
    });
  });

  group('concurrency', () {
    test('a second concurrent syncAll joins the run in progress instead of racing it', () async {
      final log = <Uri>[];
      final h = await _harness(MockClient((request) async {
        log.add(request.url);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return _page(
          changed: request.url.path.endsWith('/sync/hall') ? [_hall('hall-1', '10')] : const [],
          hasNext: false,
          nextCursor: 'c1',
        );
      }));

      final results = await Future.wait([h.engine.syncAll(), h.engine.syncAll()]);

      // One request per collection, not two: two runs interleaving pages would
      // advance each other's cursors.
      expect(log.where((uri) => uri.path.endsWith('/sync/hall')).length, 1);
      // And the second caller still gets the real outcome — it awaited fresh
      // data rather than being told "nothing happened".
      expect(results[1].changed, results[0].changed);
      expect(results[1].changed, 1);
      await h.db.close();
    });
  });

  group('scope change mid-run', () {
    test('restarts every collection, so ones synced earlier in the run are not left empty', () async {
      // 'hotel' is synced first under scope-a; 'hall' then reports scope-b. The
      // wipe discards the hotel rows too, so the run must go back and refetch
      // them — the defect was restarting only the collection that noticed.
      var hallCalls = 0;
      final h = await _harness(MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/sync/hotel')) {
          return _page(
            changed: [{'id': 'hotel-1', 'syncSeq': '5', 'hotelId': null}],
            hasNext: false,
            nextCursor: 'h1',
            scopeId: hallCalls == 0 ? 'scope-a' : 'scope-b',
          );
        }
        if (path.endsWith('/sync/hall')) {
          hallCalls += 1;
          return _page(changed: [_hall('hall-1', '10')], hasNext: false, nextCursor: 'c1', scopeId: 'scope-b');
        }
        return _page(changed: [], hasNext: false, nextCursor: null, scopeId: 'scope-b');
      }));
      await h.store.setScopeId('scope-a');

      final outcome = await h.engine.syncAll();

      expect(outcome.wiped, isTrue);
      expect(await h.store.byId('hotel', 'hotel-1'), isNotNull, reason: 'refetched after the wipe');
      expect(await h.store.byId('hall', 'hall-1'), isNotNull);
      expect(await h.store.scopeId(), 'scope-b');
      await h.db.close();
    });
  });

  group('expired cursor', () {
    test('SYNC_CURSOR_EXPIRED discards that collection and resyncs it from nothing', () async {
      final sent = <String?>[];
      final h = await _harness(MockClient((request) async {
        if (!request.url.path.endsWith('/sync/hall')) {
          return _page(changed: [], hasNext: false, nextCursor: null);
        }
        final since = request.url.queryParameters['since'];
        sent.add(since);
        if (since == 'too-old') {
          return http.Response(
            jsonEncode({'status': 'error', 'error': 'SYNC_CURSOR_EXPIRED', 'message': 'Resync required.'}),
            410,
          );
        }
        return _page(changed: [_hall('hall-fresh', '50')], hasNext: false, nextCursor: 'fresh');
      }));
      await h.store.applyPage(
        collection: 'hall',
        changed: [_hall('hall-stale', '1')],
        deleted: const [],
        nextCursor: 'too-old',
      );

      await h.engine.syncAll();

      expect(sent, ['too-old', null], reason: 'retried once, as an initial sync');
      expect(await h.store.byId('hall', 'hall-stale'), isNull, reason: 'never an empty success');
      expect(await h.store.byId('hall', 'hall-fresh'), isNotNull);
      expect(await h.store.cursorFor('hall'), 'fresh');
      await h.db.close();
    });
  });

  group('unusable cursor', () {
    test('a 400 on since resets the collection instead of failing on every run forever', () async {
      final sent = <String?>[];
      final h = await _harness(MockClient((request) async {
        if (!request.url.path.endsWith('/sync/hall')) {
          return _page(changed: [], hasNext: false, nextCursor: null);
        }
        final since = request.url.queryParameters['since'];
        sent.add(since);
        if (since == 'garbled') {
          return http.Response(
            jsonEncode({
              'status': 'error',
              'error': 'VALIDATION_ERROR',
              'message': 'invalid',
              'details': [
                {'field': 'since', 'message': 'since must be a cursor previously returned by this endpoint.'},
              ],
            }),
            400,
          );
        }
        return _page(changed: [_hall('hall-1', '5')], hasNext: false, nextCursor: 'good');
      }));
      await h.store.applyPage(collection: 'hall', changed: const [], deleted: const [], nextCursor: 'garbled');

      await h.engine.syncAll();

      expect(sent, ['garbled', null]);
      expect(await h.store.cursorFor('hall'), 'good');
      await h.db.close();
    });
  });

  group('tombstoned parents', () {
    test('a tombstoned Hall takes its local photos and blocks with it', () async {
      final h = await _harness(_server({
        'hall': [
          _page(changed: [_hall('hall-1', '10')], hasNext: false, nextCursor: 'a'),
          _page(changed: [], deleted: ['hall-1'], hasNext: false, nextCursor: 'b'),
        ],
        'hallMedia': [
          _page(changed: [_media('m-1', '11', hallId: 'hall-1')], hasNext: false, nextCursor: 'm'),
        ],
      }));

      await h.engine.syncAll();
      expect(await h.store.count('hallMedia'), 1);

      await h.engine.syncAll();
      expect(await h.store.count('hall'), 0);
      expect(await h.store.count('hallMedia'), 0, reason: 'unreachable once its Hall is gone');
      await h.db.close();
    });
  });

  group('hasSynced', () {
    test('distinguishes an empty collection from one never fetched', () async {
      final h = await _harness(_server({}));
      expect(await h.store.hasSynced('hall'), isFalse);

      await h.engine.syncAll();
      expect(await h.store.count('hall'), 0);
      expect(await h.store.hasSynced('hall'), isTrue, reason: 'synced, and genuinely empty');
      await h.db.close();
    });
  });
}
