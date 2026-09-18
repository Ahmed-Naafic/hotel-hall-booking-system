import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/chat/application/chat_badge_controller.dart';
import 'package:manager_mobile/features/chat/data/chat_repository.dart';
import 'package:manager_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:manager_mobile/features/hotel/application/hotel_context_controller.dart';
import 'package:manager_mobile/features/hotel/data/hotel_repository.dart';
import 'package:manager_mobile/features/notifications/application/notification_controller.dart';
import 'package:manager_mobile/features/notifications/data/notification_repository.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

Map<String, dynamic> _hotelJson({String status = 'APPROVED_ACTIVE'}) => {
      'id': 'h1',
      'registeredByUserId': 'u1',
      'status': status,
      'profileData': {'name': 'The Grand Hotel'},
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

const _noHotelJson = {'hotel': null, 'latestApplication': null};

http.Response _hallPageResponse(int total) => http.Response(
      jsonEncode({
        'status': 'success',
        'message': 'ok',
        'data': total == 0
            ? []
            : [
                {
                  'id': 'hall-1',
                  'hotelId': 'h1',
                  'profileData': {'name': 'The Ivory Room'},
                  'createdAt': '2026-08-25T00:00:00.000Z',
                  'updatedAt': '2026-08-25T00:00:00.000Z',
                },
              ],
        'pagination': {'page': 1, 'limit': 1, 'total': total, 'hasNext': total > 1, 'hasPrevious': false},
      }),
      200,
    );

/// Default Overview response for tests that don't care about its exact
/// numbers — deliberately distinct from any Hall-count value a test might
/// assert on, so the two never collide in `find.text(...)`.
http.Response _summaryResponse({int totalBookings = 12, int totalRevenueCents = 245000, int pendingCount = 3}) =>
    successResponse({'totalBookings': totalBookings, 'totalRevenueCents': totalRevenueCents, 'pendingCount': pendingCount});

http.Response _recentBookingsResponse([List<Map<String, dynamic>> bookings = const []]) => successResponse(bookings);

/// DashboardScreen never triggers its own `HotelContextController.load()` —
/// in the real app the bottom-navigation shell (`HomeScreen`) owns that
/// single shared load (see its doc comment). This harness plays the
/// shell's part for a standalone DashboardScreen test.
class _Harness extends StatefulWidget {
  const _Harness({required this.hotelContext, required this.child});
  final HotelContextController hotelContext;
  final Widget child;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.hotelContext.load());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget _wrap(
  Future<http.Response> Function(http.Request) handler, {
  VoidCallback? onOpenHotelTab,
  VoidCallback? onOpenHallsTab,
  VoidCallback? onOpenBookingsTab,
}) {
  final apiClient = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: InMemoryTokenStorage());
  final authController = AuthController(
    repository: AuthRepository(apiClient),
    sessionStore: SessionStore(storage: InMemoryTokenStorage()),
  );
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider<HotelContextController>.value(value: hotelContext),
      ChangeNotifierProvider<AuthController>.value(value: authController),
      ChangeNotifierProvider(create: (_) => NotificationController(NotificationRepository(apiClient))),
      ChangeNotifierProvider(create: (_) => ChatBadgeController(ChatRepository(apiClient))),
    ],
    child: _Harness(
      hotelContext: hotelContext,
      child: MaterialApp(
        home: DashboardScreen(
          onOpenHotelTab: onOpenHotelTab ?? () {},
          onOpenHallsTab: onOpenHallsTab ?? () {},
          onOpenBookingsTab: onOpenBookingsTab ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows "Set up your Hotel" when no Hotel is connected yet — never a fake summary', (tester) async {
    await tester.pumpWidget(_wrap((r) async => successResponse(_noHotelJson)));
    await tester.pumpAndSettle();

    expect(find.text('Set up your Hotel'), findsOneWidget);
  });

  testWidgets('shows the real Hall count from the Hall API, never a hardcoded number', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/hotels/me')) {
        return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
      }
      if (r.url.path.endsWith('/bookings/summary')) return _summaryResponse();
      if (r.url.path.endsWith('/bookings')) return _recentBookingsResponse();
      if (r.url.path.contains('/halls')) return _hallPageResponse(5);
      throw StateError('unexpected: ${r.method} ${r.url.path}');
    }));
    await tester.pumpAndSettle();

    expect(find.text('Total Halls'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('shows the real booking summary from the Overview endpoint, never a fake stat', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/hotels/me')) {
        return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
      }
      if (r.url.path.endsWith('/bookings/summary')) {
        return _summaryResponse(totalBookings: 42, totalRevenueCents: 1234500, pendingCount: 7);
      }
      if (r.url.path.endsWith('/bookings')) return _recentBookingsResponse();
      if (r.url.path.contains('/halls')) return _hallPageResponse(0);
      throw StateError('unexpected: ${r.method} ${r.url.path}');
    }));
    await tester.pumpAndSettle();

    expect(find.text('Total Bookings'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Total Revenue'), findsOneWidget);
    expect(find.text(r'$12,345'), findsOneWidget);
    expect(find.text('Pending Requests'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('shows the real signed-in Manager\'s name in the greeting, never a placeholder', (tester) async {
    final apiClient = ApiClient(httpClient: MockClient((r) async {
      if (r.url.path.endsWith('/hotels/me')) {
        return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
      }
      if (r.url.path.endsWith('/bookings/summary')) return _summaryResponse();
      if (r.url.path.endsWith('/bookings')) return _recentBookingsResponse();
      if (r.url.path.contains('/halls')) return _hallPageResponse(0);
      throw StateError('unexpected: ${r.method} ${r.url.path}');
    }), baseUrl: 'http://test/api/v1');
    final hotelContext = HotelContextController(repository: HotelRepository(apiClient), storage: InMemoryTokenStorage());
    final authController = AuthController(
      repository: AuthRepository(apiClient),
      sessionStore: SessionStore(storage: InMemoryTokenStorage()),
    )
      ..currentUser = AppUser.fromJson(testUser(fullName: 'Amina Yusuf'))
      ..status = AuthStatus.authenticated;

    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<HotelContextController>.value(value: hotelContext),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider(create: (_) => NotificationController(NotificationRepository(apiClient))),
        ChangeNotifierProvider(create: (_) => ChatBadgeController(ChatRepository(apiClient))),
      ],
      child: _Harness(
        hotelContext: hotelContext,
        child: const MaterialApp(
          home: DashboardScreen(onOpenHotelTab: _noop, onOpenHallsTab: _noop, onOpenBookingsTab: _noop),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Amina Yusuf'), findsOneWidget);
  });

  testWidgets('tapping the Total Halls tile opens the Halls tab', (tester) async {
    var opened = false;
    await tester.pumpWidget(_wrap(
      (r) async {
        if (r.url.path.endsWith('/hotels/me')) {
          return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
        }
        if (r.url.path.endsWith('/bookings/summary')) return _summaryResponse();
        if (r.url.path.endsWith('/bookings')) return _recentBookingsResponse();
        return _hallPageResponse(3);
      },
      onOpenHallsTab: () => opened = true,
    ));
    await tester.pumpAndSettle();
    // The stat grid sits right at the default test viewport's fold — ensure
    // it's fully scrolled into view before tapping (a hit-test can miss a
    // widget the Finder already sees, if it's only partially on-screen).
    // `scrollable` is explicit: the Overview grid is itself a (non-scrolling)
    // Scrollable too, so the default finder would match more than one.
    final outerScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Total Halls'), 200, scrollable: outerScrollable);

    await tester.tap(find.text('Total Halls'));
    await tester.pumpAndSettle();

    expect(opened, true);
  });

  testWidgets('shows the 3 most recent Bookings with customer, Hall and status', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/hotels/me')) {
        return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
      }
      if (r.url.path.endsWith('/bookings/summary')) return _summaryResponse();
      if (r.url.path.endsWith('/bookings')) {
        return _recentBookingsResponse([
          {
            'id': 'b1',
            'hallId': 'hall-1',
            'hall': {'id': 'hall-1', 'name': 'Grand Ballroom'},
            'customer': {'id': 'c1', 'fullName': 'Amina Hassan', 'mobileNumber': '+15550000001'},
            'startsAt': '2026-10-25T09:00:00.000Z',
            'endsAt': '2026-10-25T17:00:00.000Z',
            'numberOfGuests': 100,
            'eventType': 'WEDDING',
            'status': 'CONFIRMED',
            'paymentStatus': 'PAID',
            'pricing': {'totalRentCents': 100000, 'requiredAdvanceCents': 30000},
            'payment': {},
          },
        ]);
      }
      if (r.url.path.contains('/halls')) return _hallPageResponse(0);
      throw StateError('unexpected: ${r.method} ${r.url.path}');
    }));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Recent Bookings'), 300, scrollable: find.byType(Scrollable).first);

    expect(find.text('Recent Bookings'), findsOneWidget);
    expect(find.text('Amina Hassan'), findsOneWidget);
    expect(find.textContaining('Grand Ballroom'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
  });

  testWidgets('a REGISTERED Hotel shows the same onboarding action as My Hotel, never omitted', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/hotels/me')) {
        return successResponse({'hotel': _hotelJson(status: 'REGISTERED'), 'latestApplication': null});
      }
      if (r.url.path.endsWith('/bookings/summary')) return _summaryResponse();
      if (r.url.path.endsWith('/bookings')) return _recentBookingsResponse();
      return _hallPageResponse(0);
    }));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Complete your Hotel profile'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Complete your Hotel profile'), findsOneWidget);
    expect(find.text('Complete Hotel Profile'), findsOneWidget);
  });
}

void _noop() {}
