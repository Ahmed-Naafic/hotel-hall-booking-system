import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider<HotelContextController>.value(value: hotelContext),
      ChangeNotifierProvider(create: (_) => NotificationController(NotificationRepository(apiClient))),
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

  testWidgets('shows the Hotel Logo on the Home tab identity card too, when one exists', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/hotels/me')) {
        return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
      }
      if (r.url.path.endsWith('/media')) {
        return successResponse({
          'logo': {
            'id': 'logo1',
            'hotelId': 'h1',
            'type': 'LOGO',
            'url': 'https://example.com/logo.jpg',
            'createdAt': '2026-08-26T00:00:00.000Z',
            'updatedAt': '2026-08-26T00:00:00.000Z',
          },
          'photos': [],
        });
      }
      if (r.url.path.contains('/halls')) return _hallPageResponse(0);
      throw StateError('unexpected: ${r.method} ${r.url.path}');
    }));
    await tester.pumpAndSettle();

    expect(find.byType(HHNetworkImage), findsOneWidget);
  });

  testWidgets('shows the real Hall count from the Hall API, never a hardcoded number', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/hotels/me')) {
        return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
      }
      if (r.url.path.endsWith('/media')) return successResponse({'logo': null, 'photos': []});
      if (r.url.path.contains('/halls')) return _hallPageResponse(5);
      throw StateError('unexpected: ${r.method} ${r.url.path}');
    }));
    await tester.pumpAndSettle();

    expect(find.text('The Grand Hotel'), findsOneWidget);
    expect(find.text('5 Halls total'), findsOneWidget);
  });

  testWidgets('a Hotel with exactly one Hall uses singular wording, not a hardcoded plural', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/hotels/me')) {
        return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
      }
      if (r.url.path.endsWith('/media')) return successResponse({'logo': null, 'photos': []});
      if (r.url.path.contains('/halls')) return _hallPageResponse(1);
      throw StateError('unexpected: ${r.method} ${r.url.path}');
    }));
    await tester.pumpAndSettle();

    expect(find.text('1 Hall total'), findsOneWidget);
  });

  testWidgets('tapping the Hotel identity card opens the Hotel tab', (tester) async {
    var opened = false;
    await tester.pumpWidget(_wrap(
      (r) async {
        if (r.url.path.endsWith('/hotels/me')) {
          return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
        }
        if (r.url.path.endsWith('/media')) return successResponse({'logo': null, 'photos': []});
        return _hallPageResponse(0);
      },
      onOpenHotelTab: () => opened = true,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('The Grand Hotel'));
    await tester.pumpAndSettle();

    expect(opened, true);
  });

  testWidgets('tapping the Halls count card opens the Halls tab', (tester) async {
    var opened = false;
    await tester.pumpWidget(_wrap(
      (r) async {
        if (r.url.path.endsWith('/hotels/me')) {
          return successResponse({'hotel': _hotelJson(), 'latestApplication': null});
        }
        if (r.url.path.endsWith('/media')) return successResponse({'logo': null, 'photos': []});
        return _hallPageResponse(3);
      },
      onOpenHallsTab: () => opened = true,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Halls'));
    await tester.pumpAndSettle();

    expect(opened, true);
  });

  testWidgets('a REGISTERED Hotel shows the same onboarding action as My Hotel, never omitted', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/hotels/me')) {
        return successResponse({'hotel': _hotelJson(status: 'REGISTERED'), 'latestApplication': null});
      }
      if (r.url.path.endsWith('/media')) return successResponse({'logo': null, 'photos': []});
      return _hallPageResponse(0);
    }));
    await tester.pumpAndSettle();

    expect(find.text('Complete your Hotel profile'), findsOneWidget);
    expect(find.text('Complete Hotel Profile'), findsOneWidget);
  });
}
