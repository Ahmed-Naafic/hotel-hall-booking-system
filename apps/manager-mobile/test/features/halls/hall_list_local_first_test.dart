import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/sync/local_replica.dart';
import 'package:manager_mobile/core/sync/sync_database.dart';
import 'package:manager_mobile/features/halls/application/hall_list_controller.dart';
import 'package:manager_mobile/features/halls/data/hall_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The Hall list reading from the local replica (ADR-0009): what it shows,
/// when it goes to the network, and that commands still go to the server.
///
/// A fake backend holds one Hotel's Halls and answers both the REST list and
/// the sync endpoint from the same state — so a test can change the server and
/// assert what the *screen's controller* ends up holding, not which URL fired.

Map<String, dynamic> _hall(String id, String name, {bool isActive = true, required String createdAt}) => {
  'id': id,
  'hotelId': 'h1',
  'profileData': {'name': name},
  'isActive': isActive,
  'createdAt': createdAt,
  'updatedAt': createdAt,
};

class _Backend {
  _Backend() {
    halls = {
      'hall-1': _hall('hall-1', 'Grand Ballroom', createdAt: '2026-09-01T00:00:00.000Z'),
      'hall-2': _hall('hall-2', 'Garden Terrace', isActive: false, createdAt: '2026-09-02T00:00:00.000Z'),
    };
  }

  late Map<String, Map<String, dynamic>> halls;
  bool offline = false;
  int seq = 100;
  final listRequests = <Uri>[];
  final patches = <String>[];

  /// Answers REST list requests for this search only after [release] — lets a
  /// test make an older query's response arrive last.
  final slow = <String, Completer<void>>{};

  /// When set, a sync request captures the server's state immediately — as the
  /// real endpoint's snapshot does — and only then waits for this gate.
  Completer<void>? syncGate;

  MockClient get client => MockClient((request) async {
    if (offline) throw const SocketException('offline');
    final path = request.url.path;

    if (path.endsWith('/sync/hall')) {
      // Every sync returns the whole Hotel: the replica's upsert is idempotent,
      // and this keeps the fake honest about the one thing that matters here —
      // what the server currently holds.
      final rows = halls.values.map((h) => {...h, 'syncSeq': '${seq++}'}).toList();
      final gate = syncGate;
      if (gate != null) await gate.future;
      return http.Response(
        jsonEncode({
          'status': 'success',
          'message': 'ok',
          'data': {'changed': rows, 'deleted': const [], 'scopeId': 's', 'serverTime': 'x'},
          'pagination': {'limit': 100, 'hasNext': false, 'nextCursor': 'c$seq'},
        }),
        200,
      );
    }

    if (request.method == 'PATCH') {
      final id = request.url.pathSegments.last;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      halls[id] = {...halls[id]!, 'isActive': body['isActive']};
      patches.add(id);
      return http.Response(jsonEncode({'status': 'success', 'message': 'ok', 'data': halls[id]}), 200);
    }

    if (path.endsWith('/hotels/h1/halls')) {
      listRequests.add(request.url);
      final search = request.url.queryParameters['search'] ?? '';
      final gate = slow[search];
      if (gate != null) await gate.future;
      final matching = halls.values
          .where((h) => (h['profileData']['name'] as String).toLowerCase().contains(search.toLowerCase()))
          .toList();
      return http.Response(
        jsonEncode({
          'status': 'success',
          'message': 'ok',
          'data': matching,
          'pagination': {
            'page': 1, 'limit': 20, 'total': matching.length, 'totalPages': 1,
            'hasNext': false, 'hasPrevious': false,
          },
        }),
        200,
      );
    }
    return http.Response(jsonEncode({'status': 'success', 'message': 'ok', 'data': {}}), 200);
  });
}

Future<({HallListController controller, LocalReplica replica, SyncDatabase db})> _harness(
  _Backend backend, {
  bool withReplica = true,
}) async {
  final db = await SyncDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
  final api = ApiClient(httpClient: backend.client, baseUrl: 'http://test/api/v1');
  final replica = LocalReplica(apiClient: api, openDatabase: () async => db);
  final controller = HallListController(
    repository: HallRepository(api),
    hotelId: 'h1',
    replica: withReplica ? replica : null,
  );
  return (controller: controller, replica: replica, db: db);
}

/// Lets listener-driven re-reads (which are async) finish.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  setUpAll(sqfliteFfiInit);

  test('first launch reads the network, then switches to the replica once it has synced', () async {
    final backend = _Backend();
    final h = await _harness(backend);

    await h.controller.load();
    expect(h.controller.isLocal, isFalse, reason: 'nothing synced yet — an empty replica is not an empty Hotel');
    expect(h.controller.halls, hasLength(2));

    await h.replica.sync();
    await _settle();
    expect(h.controller.isLocal, isTrue);
    expect(h.controller.halls.map((h) => h.id), ['hall-2', 'hall-1'], reason: 'newest created first, as the server orders');
    h.controller.dispose();
    await h.db.close();
  });

  test('once synced, search and filters are answered locally with no list request', () async {
    final backend = _Backend();
    final h = await _harness(backend);
    await h.replica.sync();
    backend.listRequests.clear();

    await h.controller.load();
    expect(h.controller.isLocal, isTrue);

    h.controller.search = 'GRAND';
    await h.controller.load();
    expect(h.controller.halls.map((h) => h.id), ['hall-1'], reason: 'partial, case-insensitive');

    h.controller.search = '';
    h.controller.setStatusFilter('inactive');
    await _settle();
    expect(h.controller.halls.map((h) => h.id), ['hall-2']);
    expect((h.controller.allCount, h.controller.activeCount, h.controller.inactiveCount), (2, 1, 1));

    expect(backend.listRequests, isEmpty, reason: 'the replica holds the whole Hotel');
    h.controller.dispose();
    await h.db.close();
  });

  test('offline, the synced list stays on screen and says it is saved data', () async {
    final backend = _Backend();
    final h = await _harness(backend);
    await h.replica.sync();
    await h.controller.load();

    backend.offline = true;
    await h.replica.sync();
    await _settle();

    expect(h.controller.status, HallListStatus.ready);
    expect(h.controller.halls, hasLength(2));
    expect(h.controller.showingSavedData, isTrue);
    h.controller.dispose();
    await h.db.close();
  });

  test('activating a Hall is a server command, and the list shows the server’s result', () async {
    final backend = _Backend();
    final h = await _harness(backend);
    await h.replica.sync();
    await h.controller.load();
    final garden = h.controller.halls.firstWhere((hall) => hall.id == 'hall-2');

    await h.controller.setHallActive(garden, true);

    expect(backend.patches, ['hall-2'], reason: 'the command goes to the server');
    expect(h.controller.isLocal, isTrue);
    expect(h.controller.activeCount, 2, reason: 'the replica synced the server’s new state before re-reading');
    h.controller.dispose();
    await h.db.close();
  });

  test('a command sent while a sync is in flight is not undone by that older sync', () async {
    // The in-flight sync took its snapshot before the PATCH committed. If the
    // command's own sync merely joined it, the list would re-read the old
    // isActive — the toggle would appear to revert — and the freshness window
    // would then suppress the correcting sync for 30 seconds.
    final backend = _Backend();
    final h = await _harness(backend);
    await h.replica.sync();
    await h.controller.load();
    final garden = h.controller.halls.firstWhere((hall) => hall.id == 'hall-2');

    backend.syncGate = Completer<void>();
    final inFlight = h.replica.sync();
    await Future<void>.delayed(const Duration(milliseconds: 20)); // its snapshot is taken
    final command = h.controller.setHallActive(garden, true);
    await Future<void>.delayed(const Duration(milliseconds: 20)); // the PATCH has committed
    backend.syncGate!.complete();
    backend.syncGate = null;
    await inFlight;
    await command;
    await _settle();

    expect(h.controller.activeCount, 2, reason: 'the list shows the command’s result');
    expect(h.controller.halls.firstWhere((hall) => hall.id == 'hall-2').isActive, isTrue);
    h.controller.dispose();
    await h.db.close();
  });

  test('offline, a command fails instead of pretending to succeed', () async {
    final backend = _Backend();
    final h = await _harness(backend);
    await h.replica.sync();
    await h.controller.load();
    final garden = h.controller.halls.firstWhere((hall) => hall.id == 'hall-2');

    backend.offline = true;
    await expectLater(h.controller.setHallActive(garden, true), throwsA(isA<NetworkException>()));
    expect(h.controller.inactiveCount, 1, reason: 'nothing changed locally either');
    h.controller.dispose();
    await h.db.close();
  });

  test('a new Hall created on the server appears after refreshAfterCommand, inside the freshness window', () async {
    final backend = _Backend();
    final h = await _harness(backend);
    await h.replica.sync();
    await h.controller.load();

    backend.halls['hall-3'] = _hall('hall-3', 'Rooftop', createdAt: '2026-09-03T00:00:00.000Z');
    await h.controller.refreshAfterCommand();

    expect(h.controller.halls.first.id, 'hall-3');
    h.controller.dispose();
    await h.db.close();
  });

  test('network path: a slow response for a superseded search never overwrites the newer one', () async {
    final backend = _Backend();
    final h = await _harness(backend, withReplica: false);
    final gate = Completer<void>();
    backend.slow['gr'] = gate;

    h.controller.search = 'gr';
    final older = h.controller.load();
    h.controller.search = 'garden';
    await h.controller.load();
    gate.complete();
    await older;

    expect(h.controller.halls.map((h) => h.id), ['hall-2'], reason: 'the result for "garden", not "gr"');
    h.controller.dispose();
    await h.db.close();
  });
}
