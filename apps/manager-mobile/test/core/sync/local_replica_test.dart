import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/sync/local_replica.dart';
import 'package:manager_mobile/core/sync/sync_database.dart';
import 'package:manager_mobile/core/sync/sync_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../test_support.dart';

/// The app-wide replica: when it syncs, what it reports, and — the part with
/// security weight — that it is wiped when the session ends and only then.

http.Response _syncPage(
  List<Map<String, dynamic>> rows, {
  String scopeId = 'scope-a',
  String cursor = 'c',
  bool hasNext = false,
}) =>
    http.Response(
      jsonEncode({
        'status': 'success',
        'message': 'ok',
        'data': {'changed': rows, 'deleted': const [], 'scopeId': scopeId, 'serverTime': 'x'},
        'pagination': {'limit': 100, 'hasNext': hasNext, 'nextCursor': cursor},
      }),
      200,
    );

Map<String, dynamic> _hall(String id) => {
  'id': id,
  'syncSeq': '10',
  'hotelId': 'hotel-1',
  'profileData': {'name': id},
  'isActive': true,
  'createdAt': '2026-09-01T00:00:00.000Z',
};

/// A backend whose behaviour each test can change mid-flight.
class _Backend {
  bool offline = false;
  List<Map<String, dynamic>> halls = [_hall('hall-1')];
  Map<String, dynamic> me = testUser();
  int syncRequests = 0;

  /// When set, sync pages after the first wait for it; the first page says
  /// there is more, so a run is caught between two pages.
  Completer<void>? secondPageGate;

  MockClient get client => MockClient((request) async {
    if (offline) throw const SocketException('offline');
    final path = request.url.path;
    if (path.endsWith('/sync/hall')) {
      syncRequests += 1;
      final gate = secondPageGate;
      if (gate != null) {
        if (request.url.queryParameters['since'] != 'page-2') {
          return _syncPage([_hall('hall-1')], cursor: 'page-2', hasNext: true);
        }
        await gate.future;
        return _syncPage([_hall('hall-2')], cursor: 'page-3');
      }
      return _syncPage(halls);
    }
    if (path.endsWith('/auth/me')) return successResponse(me);
    if (path.endsWith('/auth/logout')) return successResponse(const <String, dynamic>{});
    return successResponse(const <String, dynamic>{});
  });
}

Future<({LocalReplica replica, SyncDatabase db, SyncStore store, ApiClient api})> _harness(
  _Backend backend, {
  Future<String?> Function()? token,
}) async {
  final db = await SyncDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
  final api = ApiClient(
    httpClient: backend.client,
    baseUrl: 'http://test/api/v1',
    accessTokenProvider: token,
  );
  final replica = LocalReplica(apiClient: api, openDatabase: () async => db);
  return (replica: replica, db: db, store: SyncStore(db), api: api);
}

void main() {
  setUpAll(sqfliteFfiInit);

  group('sync', () {
    test('fills the replica and moves the revision only when something changed', () async {
      final backend = _Backend();
      final h = await _harness(backend);
      expect(await h.replica.hasSynced('hall'), isFalse);

      await h.replica.sync();
      expect(await h.replica.hasSynced('hall'), isTrue);
      expect(await h.store.count('hall'), 1);
      final afterFirst = h.replica.revision;
      expect(afterFirst, greaterThan(0));

      backend.halls = [];
      await h.replica.sync();
      expect(h.replica.revision, afterFirst, reason: 'nothing new, so no reader needs to re-read');
      await h.db.close();
    });

    test('offline: keeps what it has, reports it, and never throws', () async {
      final backend = _Backend();
      final h = await _harness(backend);
      await h.replica.sync();

      backend.offline = true;
      await h.replica.sync();

      expect(h.replica.isOffline, isTrue);
      expect(await h.store.count('hall'), 1, reason: 'an offline sync must not cost the rows already held');

      backend.offline = false;
      await h.replica.sync();
      expect(h.replica.isOffline, isFalse);
      await h.db.close();
    });

    test('syncIfStale skips a round trip right after a sync, sync() never does', () async {
      final backend = _Backend();
      final h = await _harness(backend);

      await h.replica.sync();
      await h.replica.syncIfStale();
      expect(backend.syncRequests, 1);

      await h.replica.sync();
      expect(backend.syncRequests, 2, reason: 'after a command the replica is known stale');
      await h.db.close();
    });

    test('a database that cannot open makes the replica unavailable, not the app broken', () async {
      final backend = _Backend();
      final api = ApiClient(httpClient: backend.client, baseUrl: 'http://test/api/v1');
      final replica = LocalReplica(
        apiClient: api,
        openDatabase: () async => throw UnsupportedError('no sqlite here'),
      );

      expect(await replica.ready(), isNull);
      expect(await replica.hasSynced('hall'), isFalse, reason: 'readers fall back to the network');
      await replica.sync(); // must not throw
      await replica.clear(); // must not throw
    });
  });

  group('ordering', () {
    test('a wipe requested mid-sync waits for it, so no cursor survives pointing past deleted rows', () async {
      // Before the queue: the wipe landed between pages, the engine then stored
      // page 2's cursor, and page 1's rows were gone for good while hasSynced
      // said the collection was complete.
      final backend = _Backend()..secondPageGate = Completer<void>();
      final h = await _harness(backend);

      final syncing = h.replica.sync();
      await Future<void>.delayed(const Duration(milliseconds: 20)); // page 1 applied
      final wiping = h.replica.clear();
      backend.secondPageGate!.complete();
      await Future.wait([syncing, wiping]);

      expect(await h.store.count('hall'), 0);
      expect(await h.store.cursorFor('hall'), isNull);
      expect(await h.store.hasSynced('hall'), isFalse, reason: 'the next sync starts from nothing');
      await h.db.close();
    });

    test('sync() never throws, even when the local database fails', () async {
      final backend = _Backend();
      final h = await _harness(backend);
      await h.replica.ready();
      await h.db.close(); // every local write now fails

      await h.replica.sync(); // must complete normally
      expect(h.replica.lastError, isNotNull);
    });
  });

  group('session binding', () {
    Future<({AuthController auth, SessionStore session})> signedIn(_Backend backend) async {
      final session = SessionStore(storage: InMemoryTokenStorage());
      await session.save(accessToken: 'access', refreshToken: 'refresh', remember: true);
      final api = ApiClient(
        httpClient: backend.client,
        baseUrl: 'http://test/api/v1',
        accessTokenProvider: () => session.accessToken,
      );
      final auth = AuthController(repository: AuthRepository(api), sessionStore: session);
      return (auth: auth, session: session);
    }

    test('syncs when a verified Manager is signed in', () async {
      final backend = _Backend();
      final h = await _harness(backend);
      final s = await signedIn(backend);

      h.replica.bindAuth(s.auth);
      await s.auth.restoreSession();
      await h.replica.settled;

      expect(await h.store.count('hall'), 1);
      await h.db.close();
    });

    test('an unverified account is not synced', () async {
      final backend = _Backend()..me = testUser(isVerified: false);
      final h = await _harness(backend);
      final s = await signedIn(backend);

      h.replica.bindAuth(s.auth);
      await s.auth.restoreSession();
      await h.replica.settled;

      expect(backend.syncRequests, 0);
      await h.db.close();
    });

    test('signing out wipes the replica', () async {
      final backend = _Backend();
      final h = await _harness(backend);
      final s = await signedIn(backend);
      h.replica.bindAuth(s.auth);
      await s.auth.restoreSession();
      await h.replica.settled;
      expect(await h.store.count('hall'), 1);

      await s.auth.logout();
      await h.replica.settled;

      expect(await h.store.count('hall'), 0);
      expect(await h.store.hasSynced('hall'), isFalse);
      await h.db.close();
    });

    test('starting offline keeps the replica: the session is intact, only unreachable', () async {
      // `restoreSession` reports unauthenticated on a network failure but keeps
      // the stored tokens. Wiping then would throw away the very data
      // local-first exists to keep.
      final backend = _Backend();
      final h = await _harness(backend);
      await h.replica.sync();
      expect(await h.store.count('hall'), 1);

      final s = await signedIn(backend);
      backend.offline = true;
      h.replica.bindAuth(s.auth);
      await s.auth.restoreSession();
      await h.replica.settled;

      expect(s.auth.status, AuthStatus.unauthenticated);
      expect(await h.store.count('hall'), 1);
      await h.db.close();
    });

    test('after a restart, another user cannot read the previous user’s replica — even before any sync', () async {
      // The owner is persisted with the rows. A fresh LocalReplica (a new app
      // process) over the same database must not trust it for someone else.
      final backend = _Backend();
      final db = await SyncDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
      final first = await signedIn(backend);
      final api = ApiClient(httpClient: backend.client, baseUrl: 'http://test/api/v1');
      final before = LocalReplica(apiClient: api, openDatabase: () async => db)..bindAuth(first.auth);
      await first.auth.restoreSession();
      await before.settled;
      expect(await SyncStore(db).byId('hall', 'hall-1'), isNotNull);

      // New process, another Manager, and this time the network is down, so no
      // sync can run to notice the scope change.
      backend
        ..me = {...testUser(), 'id': 'u2'}
        ..halls = [_hall('their-hall')];
      final second = await signedIn(backend);
      final after = LocalReplica(apiClient: api, openDatabase: () async => db);
      expect(await after.hasSynced('hall'), isTrue, reason: 'unbound: nothing to check against');
      after.bindAuth(second.auth);
      expect(await after.hasSynced('hall'), isFalse, reason: 'bound, but nobody confirmed yet');

      await second.auth.restoreSession();
      backend.offline = true;
      await after.settled;

      expect(await SyncStore(db).byId('hall', 'hall-1'), isNull, reason: 'wiped on adoption, not on sync');
      expect(await SyncStore(db).ownerUserId(), 'u2');
      await db.close();
    });

    test('a different user signing in never sees the previous one’s rows', () async {
      final backend = _Backend();
      final h = await _harness(backend);
      final s = await signedIn(backend);
      h.replica.bindAuth(s.auth);
      await s.auth.restoreSession();
      await h.replica.settled;
      expect(await h.store.byId('hall', 'hall-1'), isNotNull);

      // Same device, another Manager's session, without a sign-out between.
      backend
        ..me = {...testUser(), 'id': 'u2'}
        ..halls = [_hall('their-hall')];
      await s.auth.restoreSession();
      await h.replica.settled;

      expect(await h.store.byId('hall', 'hall-1'), isNull);
      expect(await h.store.byId('hall', 'their-hall'), isNotNull);
      await h.db.close();
    });
  });
}
