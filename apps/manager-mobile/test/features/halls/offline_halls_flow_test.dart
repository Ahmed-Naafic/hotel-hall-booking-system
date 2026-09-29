import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/presentation/offline_banner.dart';
import 'package:manager_mobile/core/sync/local_replica.dart';
import 'package:manager_mobile/core/sync/sync_database.dart';
import 'package:manager_mobile/features/authentication/presentation/screens/home_screen.dart';
import 'package:manager_mobile/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:manager_mobile/features/chat/application/chat_badge_controller.dart';
import 'package:manager_mobile/features/chat/data/chat_repository.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/notifications/application/notification_controller.dart';
import 'package:manager_mobile/features/notifications/data/notification_repository.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../test_support.dart';

/// Offline, through the real app shell — every tab.
///
/// The first failure found on a device: online, then airplane mode, then
/// Home → Halls showed "Could not reach the server". Every revisit of the Home
/// or Hotel tab re-ran `HotelContextController.load()`, which turned a known
/// Hotel into an error, and the Halls tab is only built while that context is
/// `ready`. The second: every tab but Halls failed offline, because only the
/// Hall list read from the replica.
///
/// Everything below is real except the HTTP server: `HomeScreen` and its tabs,
/// the Hotel context, the replica on SQLite (in the test isolate, so the fake
/// clock drives it), the sync engine, the repositories and the app-wide
/// offline banner.

const _now = '2026-09-01T00:00:00.000Z';

Map<String, dynamic> _hotel() => {
      'id': 'h1',
      'registeredByUserId': 'u1',
      'status': 'APPROVED_ACTIVE',
      'profileData': {'name': 'The Grand Hotel'},
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
      'logo': null,
      'photos': <dynamic>[],
    };

Map<String, dynamic> _hall(String id, String name, String createdAt) => {
      'id': id,
      'hotelId': 'h1',
      'profileData': {'name': name},
      'isActive': true,
      'createdAt': createdAt,
      'updatedAt': createdAt,
    };

/// The sync row: `toBooking` with no customer and no hall loaded.
Map<String, dynamic> _bookingRow(String id, {required DateTime startsAt, String status = 'PENDING'}) => {
      'id': id,
      'customerUserId': 'c1',
      'hotelId': 'h1',
      'hallId': 'hall-1',
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': startsAt.add(const Duration(hours: 3)).toUtc().toIso8601String(),
      'numberOfGuests': 40,
      'eventType': 'WEDDING',
      'status': status,
      'paymentStatus': 'NOT_REPORTED',
      'paymentDeadlineAt': startsAt.toUtc().toIso8601String(),
      'pricing': {'currency': 'USD', 'totalRentCents': 100000, 'advancePercent': 30, 'requiredAdvanceCents': 30000},
      'payment': {'reportedAmountCents': null, 'reportedAt': null, 'verifiedAt': null, 'rejectionReason': null},
      'createdAt': _now,
      'updatedAt': _now,
      'review': null,
    };

class _Server {
  bool offline = false;
  var seq = 1;
  final halls = <Map<String, dynamic>>[
    _hall('hall-1', 'Grand Ballroom', '2026-09-01T00:00:00.000Z'),
    _hall('hall-2', 'Garden Terrace', '2026-09-02T00:00:00.000Z'),
  ];
  final bookings = <Map<String, dynamic>>[
    // Today at noon, local time: on the Calendar's default day whenever the
    // test runs.
    _bookingRow('b1', startsAt: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12)),
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

  /// The REST list: the same Bookings, with what only the server may show.
  Map<String, dynamic> _restBooking(Map<String, dynamic> row) => {
        ...row,
        'customer': {'id': 'c1', 'fullName': 'Amina Warsame', 'mobileNumber': '+252610000001', 'avatarUrl': null},
        'hall': {'id': 'hall-1', 'name': 'Grand Ballroom'},
      };

  MockClient get client => MockClient((r) async {
        if (offline) throw const SocketException('Network is unreachable');
        final path = r.url.path;
        if (path.endsWith('/auth/me')) return successResponse(testUser());
        if (path.endsWith('/sync/hotel')) return _sync([_hotel()]);
        if (path.endsWith('/sync/hall')) return _sync(halls);
        if (path.endsWith('/sync/booking')) return _sync(bookings);
        if (path.contains('/sync/')) return _sync(const []);
        if (path.endsWith('/hotels/me')) return successResponse({'hotel': _hotel(), 'latestApplication': null});
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
        if (path.endsWith('/bookings/summary')) {
          return successResponse({'totalBookings': 42, 'totalRevenueCents': 0, 'pendingCount': 7});
        }
        if (path.endsWith('/hotels/h1/bookings')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'message': 'ok',
              'data': bookings.map(_restBooking).toList(),
              'pagination': {'limit': 100, 'hasNext': false},
            }),
            200,
          );
        }
        if (path.endsWith('/media')) return successResponse({'logo': null, 'photos': <dynamic>[]});
        if (path.endsWith('/unread-count')) return successResponse({'count': 0});
        return successResponse(<dynamic>[]);
      });
}

class _App {
  _App(this.server, this.db);
  final _Server server;
  final SyncDatabase db;
  late final LocalReplica replica;

  Future<Widget> build() async {
    final session = SessionStore(storage: InMemoryTokenStorage());
    await session.save(accessToken: 'a', refreshToken: 'r', remember: true);
    final api = ApiClient(
      httpClient: server.client,
      baseUrl: 'http://test/api/v1',
      accessTokenProvider: () => session.accessToken,
    );
    final auth = AuthController(repository: AuthRepository(api), sessionStore: session);
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
            repository: HotelRepository(api, replica: replica),
            storage: InMemoryTokenStorage(),
            replica: replica,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationController(NotificationRepository(api, replica: replica)),
        ),
        ChangeNotifierProvider(create: (_) => ChatBadgeController(ChatRepository(api, replica: replica))),
      ],
      // The same app-wide banner `main.dart` installs.
      child: const MaterialApp(builder: OfflineBanner.wrap, home: HomeScreen()),
    );
  }
}

Finder _nav(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));
final _banner = find.textContaining('Offline — data may be out of date');
final _unreachable = find.textContaining('Could not reach the server');

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

/// Online first — every tab once, as a Manager would — then airplane mode.
Future<_App> _onlineThenOffline(WidgetTester tester) async {
  final server = _Server();
  final app = await _launchOnline(tester, server);
  for (final tab in ['Halls', 'Bookings', 'Calendar', 'Hotel', 'Home']) {
    await tester.tap(_nav(tab));
    await _settle(tester);
  }
  expect(_banner, findsNothing, reason: 'online: no banner');
  server.offline = true;
  return app;
}

void main() {
  setUpAll(sqfliteFfiInit);

  testWidgets('REGRESSION: online, then airplane mode, then Home → Halls shows the saved Halls, not an error',
      (tester) async {
    final app = await _onlineThenOffline(tester);

    await tester.tap(_nav('Home')); // re-runs HotelContextController.load() offline
    await _settle(tester);
    await tester.tap(_nav('Halls'));
    await _settle(tester);

    expect(_unreachable, findsNothing, reason: 'the exact message observed on the device');
    expect(find.text('Grand Ballroom'), findsOneWidget);
    expect(find.text('Garden Terrace'), findsOneWidget);
    expect(_banner, findsOneWidget);
    await app.db.close();
  });

  testWidgets('offline, the Bookings tab shows the saved Bookings — with no customer contact details',
      (tester) async {
    final app = await _onlineThenOffline(tester);

    await tester.tap(_nav('Bookings'));
    await _settle(tester);

    expect(_unreachable, findsNothing);
    expect(find.textContaining('Grand Ballroom'), findsWidgets, reason: 'the Hall name, joined locally');
    expect(find.textContaining('Amina Warsame'), findsNothing, reason: 'contact details are never replicated');
    expect(find.textContaining('+252610000001'), findsNothing);
    expect(_banner, findsOneWidget);
    await app.db.close();
  });

  testWidgets('offline, the Calendar shows the saved Bookings on their day', (tester) async {
    final app = await _onlineThenOffline(tester);

    await tester.tap(_nav('Calendar'));
    await _settle(tester);

    expect(find.text('Unable to load bookings.'), findsNothing);
    // The day's list sits below the month grid, outside the test viewport.
    final booking = find.descendant(of: find.byType(CalendarScreen), matching: find.textContaining('Grand Ballroom'));
    await tester.scrollUntilVisible(
      booking,
      200,
      scrollable: find.descendant(of: find.byType(CalendarScreen), matching: find.byType(Scrollable)).first,
    );
    expect(booking, findsWidgets);
    await app.db.close();
  });

  testWidgets('offline, Home shows the last server summary and the saved recent Bookings', (tester) async {
    final app = await _onlineThenOffline(tester);

    await tester.tap(_nav('Hotel'));
    await _settle(tester);
    await tester.tap(_nav('Home')); // refreshes every stat, offline
    await _settle(tester);

    expect(find.text('42'), findsOneWidget, reason: 'Total Bookings — the last summary the server returned');
    expect(find.text('7'), findsOneWidget, reason: 'Pending Requests');
    expect(find.text('Unable to load recent bookings.'), findsNothing);
    expect(_banner, findsOneWidget);
    await app.db.close();
  });

  testWidgets('offline, the Hotel tab keeps the Hotel', (tester) async {
    final app = await _onlineThenOffline(tester);

    await tester.tap(_nav('Hotel'));
    await _settle(tester);

    expect(_unreachable, findsNothing);
    expect(find.textContaining('The Grand Hotel'), findsWidgets);
    await app.db.close();
  });

  testWidgets('reconnecting clears the banner and brings in what changed on the server', (tester) async {
    final app = await _onlineThenOffline(tester);
    await tester.tap(_nav('Halls'));
    await _settle(tester);
    expect(_banner, findsOneWidget);

    app.server
      ..offline = false
      ..halls.add(_hall('hall-3', 'Rooftop', '2026-09-03T00:00:00.000Z'));
    await tester.tap(_nav('Home'));
    await _settle(tester);
    await tester.tap(_nav('Halls'));
    await _settle(tester);

    expect(_banner, findsNothing);
    expect(find.text('Rooftop'), findsOneWidget);
    await app.db.close();
  });
}
