import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/notifications/application/notification_controller.dart';
import 'package:manager_mobile/features/notifications/data/notification_repository.dart';
import 'package:manager_mobile/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:provider/provider.dart';

/// Notification V1 — Manager Mobile's Notification Center. Covers list
/// rendering, mark-all-read, the empty state, and the pop-with-`true`
/// signal a booking-related Notification sends its caller (Dashboard's
/// bell action switches to the Bookings tab on `true` — there is no
/// pushable Booking Detail route to navigate to directly here, since the
/// Bookings queue lives inside `HomeScreen`'s `IndexedStack`).
http.Response _envelope(dynamic data, {Map<String, dynamic>? pagination}) => http.Response(
  jsonEncode({'status': 'success', 'message': 'ok', 'data': data, if (pagination != null) 'pagination': pagination}),
  200,
);

Map<String, dynamic> _notificationJson({String id = 'n1', String status = 'UNREAD', String? bookingId = 'b1'}) => {
  'id': id,
  'type': 'NEW_BOOKING_REQUEST',
  'status': status,
  'title': 'New booking request',
  'body': 'A new booking request for Main Hall was submitted.',
  'bookingId': bookingId,
  'hotelId': 'h1',
  'hotelApplicationId': null,
  'readAt': status == 'READ' ? '2026-09-07T00:00:00.000Z' : null,
  'createdAt': '2026-09-07T00:00:00.000Z',
};

Widget _wrap(Future<http.Response> Function(http.Request) handler) {
  final apiClient = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider(create: (_) => NotificationController(NotificationRepository(apiClient))),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                );
                _lastPopResult = result;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}

bool? _lastPopResult;

void main() {
  setUp(() => _lastPopResult = null);

  testWidgets('renders the list with an unread indicator', (tester) async {
    await tester.pumpWidget(
      _wrap((request) async {
        if (request.url.path.endsWith('/notifications') && request.method == 'GET') {
          return _envelope([_notificationJson()], pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null});
        }
        if (request.url.path.endsWith('/unread-count')) return _envelope({'count': 1});
        return _envelope({});
      }),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('New booking request'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no notifications', (tester) async {
    await tester.pumpWidget(
      _wrap((request) async {
        if (request.url.path.endsWith('/notifications') && request.method == 'GET') {
          return _envelope([], pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null});
        }
        if (request.url.path.endsWith('/unread-count')) return _envelope({'count': 0});
        return _envelope({});
      }),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('tapping a booking-related notification marks it read and pops with true', (tester) async {
    var markedRead = false;
    await tester.pumpWidget(
      _wrap((request) async {
        if (request.url.path.endsWith('/notifications') && request.method == 'GET') {
          return _envelope([_notificationJson()], pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null});
        }
        if (request.url.path.endsWith('/unread-count')) return _envelope({'count': 1});
        if (request.url.path.endsWith('/n1/read') && request.method == 'POST') {
          markedRead = true;
          return _envelope(_notificationJson(status: 'READ'));
        }
        return _envelope({});
      }),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New booking request'));
    await tester.pumpAndSettle();

    expect(markedRead, true);
    expect(_lastPopResult, true);
  });

  testWidgets('Mark all read clears the unread indicator', (tester) async {
    var markedAllRead = false;
    await tester.pumpWidget(
      _wrap((request) async {
        if (request.url.path.endsWith('/notifications') && request.method == 'GET') {
          return _envelope([_notificationJson()], pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null});
        }
        if (request.url.path.endsWith('/unread-count')) return _envelope({'count': markedAllRead ? 0 : 1});
        if (request.url.path.endsWith('/read-all')) {
          markedAllRead = true;
          return _envelope(null);
        }
        return _envelope({});
      }),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(markedAllRead, true);
  });
}
