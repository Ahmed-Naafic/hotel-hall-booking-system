import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/sync/local_replica.dart';
import 'package:manager_mobile/core/sync/sync_database.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/home_screen.dart';
import 'package:manager_mobile/features/chat/application/chat_badge_controller.dart';
import 'package:manager_mobile/features/chat/data/chat_repository.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/notifications/application/notification_controller.dart';
import 'package:manager_mobile/features/notifications/data/notification_repository.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../test_support.dart';

/// The manually-observed failure, reproduced through the real app shell:
///
///   1. open Hotel Manager online  2. turn on airplane mode
///   3. open / reopen Halls         4. "Could not reach the server"
///
/// Root cause: every revisit of the Home or Hotel tab re-runs
/// `HotelContextController.load()`, which turned an already-known Hotel into
/// an error when the server was unreachable — and the Halls tab is only built
/// while that context is `ready`. The local-first Hall list was never reached.
///
/// Everything below is real except the HTTP server: `HomeScreen`, the Hotel
/// context, the replica on SQLite (`sqflite_common_ffi`), the sync engine and
/// the Hall list. SQLite runs in the test isolate (`databaseFactoryFfiNoIsolate`)
/// so the widget test's fake clock drives all of it.

Map<String, dynamic> _hotel() => {
      'id': 'h1',
      'registeredByUserId': 'u1',
      'status': 'APPROVED_ACTIVE',
      'profileData': {'name': 'The Grand Hotel'},
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

Map<String, dynamic> _hall(String id, String name, String createdAt) => {
      'id': id,
      'hotelId': 'h1',
      'profileData': {'name': name},
      'isActive': true,
      'createdAt': createdAt,
      'updatedAt': createdAt,
    };

class _Server {
  bool offline = false;
  var seq = 1;
  final halls = <Map<String, dynamic>>[
    _hall('hall-1', 'Grand Ballroom', '2026-09-01T00:00:00.000Z'),
    _hall('hall-2', 'Garden Terrace', '2026-09-02T00:00:00.000Z'),
  ];

  http.Response _sync(List<Map<String, dynamic>> rows) => http.Response(
        jsonEncode({
          'status': 'success',
          'message': 'ok',
          'data': {
            'changed': [for (final r in rows) {...r, 'syncSeq': '${seq++}'}],
            'deleted': const [],
            'scopeId': 'scope-u1',
            'serverTime': 'x',
          },
          'pagination': {'limit': 100, 'hasNext': false, 'nextCursor': 'c$seq'},
        }),
        200,
      );

  MockClient get client => MockClient((r) async {
        if (offline) throw const SocketException('Network is unreachable');
        final path = r.url.path;
        if (path.endsWith('/auth/me')) return successResponse(testUser());
        if (path.endsWith('/sync/hotel')) return _sync([_hotel()]);
        if (path.endsWith('/sync/hall')) return _sync(halls);
        if (path.endsWith('/hotels/me')) {
          return successResponse({'hotel': _hotel(), 'latestApplication': null});
        }
        if (path.endsWith('/hotels/h1/halls')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'message': 'ok',
              'data': halls,
              'pagination': {'page': 1, 'limit': 20, 'total': halls.length, 'hasNext': false, 'hasPrevious': false},
            }),
            200,
          );
        }
        if (path.endsWith('/media')) return successResponse({'logo': null, 'photos': []});
        if (path.endsWith('/bookings/summary')) {
          return successResponse({'totalBookings': 0, 'totalRevenueCents': 0, 'pendingCount': 0});
        }
        if (path.endsWith('/unread-count')) return successResponse({'count': 0});
        return successResponse(<dynamic>[]);
      });
}

class _App {
  _App(this.server, this.db);
  final _Server server;
  final SyncDatabase db;
  late final ApiClient api;
  late final AuthController auth;
  late final LocalReplica replica;

  Future<Widget> build() async {
    final session = SessionStore(storage: InMemoryTokenStorage());
    await session.save(accessToken: 'a', refreshToken: 'r', remember: true);
    api = ApiClient(
      httpClient: server.client,
      baseUrl: 'http://test/api/v1',
      accessTokenProvider: () => session.accessToken,
    );
    auth = AuthController(repository: AuthRepository(api), sessionStore: session);
    replica = LocalReplica(apiClient: api, openDatabase: () async => db)..bindAuth(auth);
    await auth.restoreSession();
    await replica.settled;
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<AuthController>.value(value: auth),
        ChangeNotifierProvider<LocalReplica>.value(value: replica),
        ChangeNotifierProvider<HotelContextController>(
          create: (_) => HotelContextController(
            repository: HotelRepository(api),
            storage: InMemoryTokenStorage(),
            replica: replica,
          ),
        ),
        ChangeNotifierProvider(create: (_) => NotificationController(NotificationRepository(api))),
        ChangeNotifierProvider(create: (_) => ChatBadgeController(ChatRepository(api))),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }
}

Finder _nav(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Lets the fake server, SQLite and every listener-driven re-read finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_App> _launchOnline(WidgetTester tester, _Server server) async {
  final db = await SyncDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
  final app = _App(server, db);
  final widget = await app.build();
  await tester.pumpWidget(widget);
  await _settle(tester);
  return app;
}

void main() {
  setUpAll(sqfliteFfiInit);

  testWidgets('REGRESSION: online, then airplane mode, then Home → Halls shows the saved Halls, not an error',
      (tester) async {
    final server = _Server();
    final app = await _launchOnline(tester, server);

    await tester.tap(_nav('Halls'));
    await _settle(tester);
    expect(find.text('Grand Ballroom'), findsOneWidget, reason: 'online: the list is there');

    // Airplane mode, then exactly the manual steps: another tab, then Halls.
    server.offline = true;
    await tester.tap(_nav('Home')); // re-runs HotelContextController.load() offline
    await _settle(tester);
    await tester.tap(_nav('Halls'));
    await _settle(tester);

    expect(find.textContaining('Could not reach the server'), findsNothing,
        reason: 'the exact message observed on the device');
    expect(find.text('Grand Ballroom'), findsOneWidget);
    expect(find.text('Garden Terrace'), findsOneWidget);
    expect(find.textContaining('Offline — data may be out of date'), findsOneWidget);

    await app.db.close();
  });

  testWidgets('offline revisit of the Hotel tab does not tear down the Halls tab either', (tester) async {
    final server = _Server();
    final app = await _launchOnline(tester, server);

    server.offline = true;
    await tester.tap(_nav('Hotel'));
    await _settle(tester);
    await tester.tap(_nav('Halls'));
    await _settle(tester);

    expect(find.textContaining('Could not reach the server'), findsNothing);
    expect(find.text('Grand Ballroom'), findsOneWidget);
    await app.db.close();
  });

  testWidgets('reconnecting clears the notice and brings in what changed on the server', (tester) async {
    final server = _Server();
    final app = await _launchOnline(tester, server);
    await tester.tap(_nav('Halls'));
    await _settle(tester);

    server.offline = true;
    await tester.tap(_nav('Home'));
    await _settle(tester);
    await tester.tap(_nav('Halls'));
    await _settle(tester);
    expect(find.textContaining('Offline — data may be out of date'), findsOneWidget);

    server
      ..offline = false
      ..halls.add(_hall('hall-3', 'Rooftop', '2026-09-03T00:00:00.000Z'));
    await tester.tap(_nav('Home'));
    await _settle(tester);
    await tester.tap(_nav('Halls'));
    await _settle(tester);

    expect(find.textContaining('Offline — data may be out of date'), findsNothing);
    expect(find.text('Rooftop'), findsOneWidget);
    await app.db.close();
  });
}
