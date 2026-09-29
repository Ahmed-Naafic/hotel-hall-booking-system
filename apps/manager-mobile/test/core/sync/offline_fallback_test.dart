import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/sync/local_replica.dart';
import 'package:manager_mobile/core/sync/offline_fallback.dart';
import 'package:manager_mobile/core/sync/sync_database.dart';
import 'package:manager_mobile/features/bookings/data/booking_repository.dart';
import 'package:manager_mobile/features/chat/data/chat_repository.dart';
import 'package:manager_mobile/features/halls/data/hall_repository.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/notifications/data/notification_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../test_support.dart';

/// Server first, replica when the server cannot be reached — for every screen
/// outside the Hall list. Each repository against a real SQLite replica and a
/// fake server that can be switched off.

Map<String, dynamic> _row(Map<String, dynamic> row, int seq) => {...row, 'syncSeq': '$seq'};

class _Server {
  bool offline = false;
  int? failWith;
  final collections = <String, List<Map<String, dynamic>>>{
    'hotel': [
      {
        'id': 'h1', 'registeredByUserId': 'u1', 'status': 'APPROVED_ACTIVE',
        'profileData': {'name': 'The Grand Hotel'},
        'createdAt': '2026-08-25T00:00:00.000Z', 'updatedAt': '2026-08-25T00:00:00.000Z',
        'logo': {'id': 'm-logo', 'hotelId': 'h1', 'type': 'LOGO', 'url': 'https://cdn.test/logo.jpg',
                 'createdAt': '2026-08-25T00:00:00.000Z', 'updatedAt': '2026-08-25T00:00:00.000Z'},
        'photos': <dynamic>[],
      },
    ],
    'hall': [
      {'id': 'hall-1', 'hotelId': 'h1', 'profileData': {'name': 'Grand Ballroom'}, 'isActive': true,
       'createdAt': '2026-09-01T00:00:00.000Z', 'updatedAt': '2026-09-01T00:00:00.000Z',
       'photos': [{'id': 'p1', 'type': 'PHOTO', 'url': 'https://cdn.test/p1.jpg'}]},
      {'id': 'hall-x', 'hotelId': 'other-hotel', 'profileData': {'name': 'Not mine'}, 'isActive': true,
       'createdAt': '2026-09-01T00:00:00.000Z', 'updatedAt': '2026-09-01T00:00:00.000Z'},
    ],
    'booking': [
      for (final (id, created) in [('b-old', '2026-09-01T00:00:00.000Z'), ('b-new', '2026-09-05T00:00:00.000Z')])
        {
          'id': id, 'customerUserId': 'c1', 'hotelId': 'h1', 'hallId': 'hall-1',
          'startsAt': '2026-10-01T10:00:00.000Z', 'endsAt': '2026-10-01T13:00:00.000Z',
          'numberOfGuests': 30, 'eventType': 'WEDDING', 'status': 'PENDING', 'paymentStatus': 'NOT_REPORTED',
          'pricing': {'currency': 'USD', 'totalRentCents': 1000, 'advancePercent': 30, 'requiredAdvanceCents': 300},
          'payment': {'reportedAmountCents': null},
          'createdAt': created, 'updatedAt': created,
        },
    ],
    'notification': [
      {'id': 'n1', 'type': 'NEW_BOOKING_REQUEST', 'title': 'Old', 'body': 'b', 'status': 'READ',
       'createdAt': '2026-09-01T00:00:00.000Z', 'readAt': '2026-09-01T01:00:00.000Z'},
      {'id': 'n2', 'type': 'NEW_BOOKING_REQUEST', 'title': 'New', 'body': 'b', 'status': 'UNREAD',
       'createdAt': '2026-09-02T00:00:00.000Z', 'readAt': null},
    ],
    'chatMessage': [
      {'id': 'm2', 'bookingId': 'b-new', 'senderUserId': 'c1', 'body': 'Second', 'readAt': null,
       'createdAt': '2026-09-03T00:00:00.000Z'},
      {'id': 'm1', 'bookingId': 'b-new', 'senderUserId': 'c1', 'body': 'First', 'readAt': null,
       'createdAt': '2026-09-02T00:00:00.000Z'},
      {'id': 'm3', 'bookingId': 'b-new', 'senderUserId': 'u1', 'body': 'Mine', 'readAt': null,
       'createdAt': '2026-09-04T00:00:00.000Z'},
      {'id': 'm4', 'bookingId': 'b-old', 'senderUserId': 'c1', 'body': 'Other conversation',
       'readAt': '2026-09-02T00:00:00.000Z', 'createdAt': '2026-09-01T00:00:00.000Z'},
    ],
  };

  MockClient get client => MockClient((r) async {
        if (offline) throw const SocketException('offline');
        if (failWith != null) return errorResponse('INTERNAL_ERROR', 'Server exploded.', failWith!);
        final path = r.url.path;
        if (path.endsWith('/auth/me')) return successResponse(testUser());
        if (path.contains('/sync/')) {
          final name = r.url.pathSegments.last;
          var seq = 1;
          return http.Response(
            jsonEncode({
              'status': 'success',
              'message': 'ok',
              'data': {
                'changed': [for (final row in collections[name] ?? const []) _row(row, seq++)],
                'deleted': const [],
                'scopeId': 's',
                'serverTime': 'x',
              },
              'pagination': {'limit': 100, 'hasNext': false, 'nextCursor': 'c'},
            }),
            200,
          );
        }
        if (path.endsWith('/bookings/summary')) {
          return successResponse({'totalBookings': 42, 'totalRevenueCents': 5000, 'pendingCount': 7});
        }
        return successResponse(const <String, dynamic>{'count': 0});
      });
}

late SyncDatabase _db;

Future<({_Server server, ApiClient api, LocalReplica replica})> _signedInAndSynced() async {
  final server = _Server();
  final session = SessionStore(storage: InMemoryTokenStorage());
  await session.save(accessToken: 'a', refreshToken: 'r', remember: true);
  final api = ApiClient(
    httpClient: server.client,
    baseUrl: 'http://test/api/v1',
    accessTokenProvider: () => session.accessToken,
  );
  final auth = AuthController(repository: AuthRepository(api), sessionStore: session);
  final replica = LocalReplica(apiClient: api, openDatabase: () async => _db)..bindAuth(auth);
  await auth.restoreSession();
  await replica.settled;
  return (server: server, api: api, replica: replica);
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() async => _db = await SyncDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath));
  tearDown(() => _db.close());

  group('serverFirst', () {
    test('online: the server answers, and an earlier offline state clears', () async {
      final s = await _signedInAndSynced();
      s.replica.noteUnreachable(const NetworkException('earlier'));
      final value = await serverFirst(s.replica, online: () async => 'server', local: (_) async => 'local');
      expect(value, 'server');
      expect(s.replica.isOffline, isFalse);
    });

    test('offline: the replica answers, and says so', () async {
      final s = await _signedInAndSynced();
      final value = await serverFirst<String>(
        s.replica,
        online: () async => throw const NetworkException('down'),
        local: (_) async => 'local',
      );
      expect(value, 'local');
      expect(s.replica.isOffline, isTrue);
    });

    test('a server error is never replaced by saved data', () async {
      final s = await _signedInAndSynced();
      await expectLater(
        serverFirst<String>(
          s.replica,
          online: () async => throw const ApiException(statusCode: 500, error: 'X', message: 'boom'),
          local: (_) async => 'local',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(s.replica.isOffline, isFalse);
    });

    test('nothing saved, or no replica: the original failure stands', () async {
      final s = await _signedInAndSynced();
      await expectLater(
        serverFirst<String>(s.replica,
            online: () async => throw const NetworkException('down'), local: (_) async => null),
        throwsA(isA<NetworkException>()),
      );
      await expectLater(
        serverFirst<String>(null, online: () async => throw const NetworkException('down'), local: (_) async => 'x'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('Bookings', () {
    test('offline list: newest first, Hall names joined locally, no customer details', () async {
      final s = await _signedInAndSynced();
      s.server.offline = true;
      final bookings = await ManagerBookingRepository(s.api, replica: s.replica).list('h1');
      expect(bookings.map((b) => b.id), ['b-new', 'b-old']);
      expect(bookings.first.hallName, 'Grand Ballroom');
      expect(bookings.first.customerFullName, isNull);
      expect(bookings.first.customerMobileNumber, isNull);
    });

    test('offline summary is the last one the server returned — never recomputed', () async {
      final s = await _signedInAndSynced();
      final repo = ManagerBookingRepository(s.api, replica: s.replica);
      await repo.summary('h1'); // online, saved
      s.server.offline = true;
      final summary = await repo.summary('h1');
      expect((summary.totalBookings, summary.totalRevenueCents, summary.pendingCount), (42, 5000, 7));
    });

    test('offline summary with none saved yet is still an error', () async {
      final s = await _signedInAndSynced();
      s.server.offline = true;
      await expectLater(
        ManagerBookingRepository(s.api, replica: s.replica).summary('h1'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('an action offline fails — it is never answered locally', () async {
      final s = await _signedInAndSynced();
      s.server.offline = true;
      await expectLater(
        ManagerBookingRepository(s.api, replica: s.replica).action('h1', 'b-new', 'confirm'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('Notifications', () {
    test('offline list is newest first, in one page, filterable by status', () async {
      final s = await _signedInAndSynced();
      s.server.offline = true;
      final repo = NotificationRepository(s.api, replica: s.replica);
      final all = await repo.list();
      expect(all.notifications.map((n) => n.id), ['n2', 'n1']);
      expect(all.hasNext, isFalse);
      final unread = await repo.list(status: 'UNREAD');
      expect(unread.notifications.map((n) => n.id), ['n2']);
      expect((await repo.list(cursor: 'next')).notifications, isEmpty);
      expect(await repo.unreadCount(), 1);
    });

    test('marking read offline fails — the server holds read state', () async {
      final s = await _signedInAndSynced();
      s.server.offline = true;
      await expectLater(NotificationRepository(s.api, replica: s.replica).markRead('n2'), throwsA(isA<NetworkException>()));
    });
  });

  group('Chat', () {
    test('offline conversation is that Booking’s messages only, oldest first', () async {
      final s = await _signedInAndSynced();
      s.server.offline = true;
      final result = await ChatRepository(s.api, replica: s.replica).list('b-new');
      expect(result.messages.map((m) => m.body), ['First', 'Second', 'Mine']);
    });

    test('offline unread count: others’ unread messages, never my own or read ones', () async {
      final s = await _signedInAndSynced();
      s.server.offline = true;
      expect(await ChatRepository(s.api, replica: s.replica).unreadCount(), 2);
    });

    test('sending offline fails — a message exists once the server has it', () async {
      final s = await _signedInAndSynced();
      s.server.offline = true;
      await expectLater(ChatRepository(s.api, replica: s.replica).send('b-new', 'hi'), throwsA(isA<NetworkException>()));
    });
  });

  group('Hotel and Halls', () {
    test('offline Hotel and its media come from the synced Hotel', () async {
      final s = await _signedInAndSynced();
      s.server.offline = true;
      final repo = HotelRepository(s.api, replica: s.replica);
      expect((await repo.getHotel('h1')).id, 'h1');
      expect((await repo.getMedia('h1')).logo?.url, 'https://cdn.test/logo.jpg');
    });

    test('offline Hall, its photos and the Hall count — own Hotel only', () async {
      final s = await _signedInAndSynced();
      s.server.offline = true;
      final repo = HallRepository(s.api, replica: s.replica);
      expect((await repo.getHall(hotelId: 'h1', id: 'hall-1')).displayTitle, 'Grand Ballroom');
      expect((await repo.getMedia(hotelId: 'h1', hallId: 'hall-1')).map((p) => p.url), ['https://cdn.test/p1.jpg']);
      expect((await repo.listHalls(hotelId: 'h1', limit: 1)).total, 1);
      await expectLater(
        repo.getHall(hotelId: 'h1', id: 'hall-x'),
        throwsA(isA<NetworkException>()),
        reason: 'another Hotel’s Hall is not found, offline as online',
      );
    });
  });
}
