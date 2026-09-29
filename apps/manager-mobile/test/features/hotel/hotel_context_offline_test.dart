import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/sync/local_replica.dart';
import 'package:manager_mobile/core/sync/sync_database.dart';
import 'package:manager_mobile/core/sync/sync_store.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../test_support.dart';

/// `HotelContextController` offline. Every Halls screen needs the Manager's
/// Hotel id first, so this controller is the gate the local-first Hall list sits
/// behind — and it used to require the network on every tab revisit.

Map<String, dynamic> _hotel(String id, {String owner = 'u1', String createdAt = '2026-08-25T00:00:00.000Z'}) => {
      'id': id,
      'registeredByUserId': owner,
      'status': 'APPROVED_ACTIVE',
      'profileData': {'name': 'Hotel $id'},
      'createdAt': createdAt,
      'updatedAt': createdAt,
    };

class _Server {
  bool offline = false;
  int status = 200;
  String userId = 'u1';
  List<Map<String, dynamic>> ownHotels = [_hotel('h1')];

  MockClient get client => MockClient((r) async {
        if (offline) throw const SocketException('offline');
        final path = r.url.path;
        if (status != 200) return errorResponse('INTERNAL_ERROR', 'Server error.', status);
        if (path.endsWith('/auth/me')) return successResponse({...testUser(), 'id': userId});
        if (path.endsWith('/hotels/me')) {
          return successResponse({'hotel': ownHotels.last, 'latestApplication': null});
        }
        if (path.endsWith('/sync/hotel') || path.endsWith('/sync/hall')) {
          final rows = path.endsWith('/sync/hotel') ? ownHotels : const <Map<String, dynamic>>[];
          return http.Response(
            jsonEncode({
              'status': 'success',
              'message': 'ok',
              'data': {
                'changed': [for (final h in rows) {...h, 'syncSeq': '1'}],
                'deleted': const [],
                'scopeId': 'scope-$userId',
                'serverTime': 'x',
              },
              'pagination': {'limit': 100, 'hasNext': false, 'nextCursor': 'c'},
            }),
            200,
          );
        }
        return successResponse(const <String, dynamic>{});
      });
}

Future<({LocalReplica replica, AuthController auth, ApiClient api})> _signedIn(
  _Server server,
  SyncDatabase db,
) async {
  final session = SessionStore(storage: InMemoryTokenStorage());
  await session.save(accessToken: 'a', refreshToken: 'r', remember: true);
  final api = ApiClient(
    httpClient: server.client,
    baseUrl: 'http://test/api/v1',
    accessTokenProvider: () => session.accessToken,
  );
  final auth = AuthController(repository: AuthRepository(api), sessionStore: session);
  final replica = LocalReplica(apiClient: api, openDatabase: () async => db)..bindAuth(auth);
  await auth.restoreSession();
  await replica.settled;
  return (replica: replica, auth: auth, api: api);
}

HotelContextController _context(ApiClient api, {LocalReplica? replica}) =>
    HotelContextController(repository: HotelRepository(api), storage: InMemoryTokenStorage(), replica: replica);

void main() {
  setUpAll(sqfliteFfiInit);

  late SyncDatabase db;
  setUp(() async => db = await SyncDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath));
  tearDown(() => db.close());

  test('an offline refresh keeps the known Hotel and says it is offline', () async {
    final server = _Server();
    final s = await _signedIn(server, db);
    final context = _context(s.api, replica: s.replica);
    await context.load();
    expect(context.status, HotelContextStatus.ready);

    server.offline = true;
    final seen = <HotelContextStatus>[];
    context.addListener(() => seen.add(context.status));
    await context.load();

    expect(context.status, HotelContextStatus.ready);
    expect(context.hotel?.id, 'h1');
    expect(context.isOffline, isTrue);
    expect(seen, isNot(contains(HotelContextStatus.loading)),
        reason: 'a revalidation must not flash the tabs built on this context');
    expect(seen, isNot(contains(HotelContextStatus.error)));
  });

  test('with nothing known, the Hotel comes from the replica when offline', () async {
    final server = _Server();
    final s = await _signedIn(server, db); // the sign-in sync replicated the Hotel
    server.offline = true;

    final context = _context(s.api, replica: s.replica);
    await context.load();

    expect(context.status, HotelContextStatus.ready);
    expect(context.hotel?.id, 'h1');
    expect(context.isOffline, isTrue);
    expect(context.latestApplication, isNull, reason: 'not replicated, so unknown offline — never invented');
  });

  test('the replica fallback picks the newest Hotel, as /hotels/me does', () async {
    final server = _Server()
      ..ownHotels = [
        _hotel('old', createdAt: '2026-01-01T00:00:00.000Z'),
        _hotel('new', createdAt: '2026-06-01T00:00:00.000Z'),
      ];
    final s = await _signedIn(server, db);
    server.offline = true;

    final context = _context(s.api, replica: s.replica);
    await context.load();
    expect(context.hotel?.id, 'new');
  });

  test('first-ever launch offline, nothing cached: still an error, as before', () async {
    final server = _Server()..offline = true;
    final api = ApiClient(httpClient: server.client, baseUrl: 'http://test/api/v1');
    final replica = LocalReplica(apiClient: api, openDatabase: () async => db);

    final context = _context(api, replica: replica);
    await context.load();

    expect(context.status, HotelContextStatus.error);
    expect(context.errorMessage, contains('Could not reach the server'));
  });

  test('a server error is still an error — only an unreachable server is tolerated', () async {
    final server = _Server();
    final s = await _signedIn(server, db);
    final context = _context(s.api, replica: s.replica);
    await context.load();

    server.status = 500;
    await context.load();
    expect(context.status, HotelContextStatus.error);
    expect(context.isOffline, isFalse);
  });

  test('coming back online clears the offline flag', () async {
    final server = _Server();
    final s = await _signedIn(server, db);
    final context = _context(s.api, replica: s.replica);
    await context.load();
    server.offline = true;
    await context.load();
    expect(context.isOffline, isTrue);

    server.offline = false;
    await context.load();
    expect(context.isOffline, isFalse);
    expect(context.status, HotelContextStatus.ready);
  });

  test('Manager B, offline, can never resolve Manager A’s Hotel from the replica', () async {
    // A synced on this device. B signs in on the same device (the scope would
    // only be compared at B's first successful sync — the network drops first).
    final server = _Server();
    await _signedIn(server, db);
    expect(await SyncStore(db).byId('hotel', 'h1'), isNotNull);

    server
      ..userId = 'u2'
      ..ownHotels = [_hotel('h-b', owner: 'u2')];
    final b = await _signedIn(server, db);
    server.offline = true;

    final context = _context(b.api, replica: b.replica);
    await context.load();

    expect(context.hotel?.id, isNot('h1'), reason: 'A’s Hotel must never be B’s context');
    expect(await SyncStore(db).byId('hotel', 'h1'), isNull, reason: 'wiped when B was adopted');
  });

  test('without a replica, offline behaves exactly as it always did', () async {
    final server = _Server()..offline = true;
    final api = ApiClient(httpClient: server.client, baseUrl: 'http://test/api/v1');
    final context = _context(api);
    await context.load();
    expect(context.status, HotelContextStatus.error);
  });
}
