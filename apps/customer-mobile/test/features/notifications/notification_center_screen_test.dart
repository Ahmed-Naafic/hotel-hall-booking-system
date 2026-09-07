import 'dart:convert';

import 'package:customer_mobile/features/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:customer_mobile/features/notifications/application/notification_controller.dart';
import 'package:customer_mobile/features/notifications/data/notification_repository.dart';
import 'package:customer_mobile/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

/// Notification V1 — Customer Mobile's Notification Center. Covers list
/// rendering (unread visual state), mark-one-read-on-tap with navigation to
/// Booking Detail, mark-all-read, and the empty state — the backend is
/// mocked at the HTTP boundary, the same pattern every other screen test
/// in this suite already uses.
http.Response _envelope(dynamic data, {Map<String, dynamic>? pagination}) => http.Response(
  jsonEncode({'status': 'success', 'message': 'ok', 'data': data, if (pagination != null) 'pagination': pagination}),
  200,
);

Map<String, dynamic> _notificationJson({
  String id = 'n1',
  String type = 'BOOKING_CONFIRMED',
  String status = 'UNREAD',
  String? bookingId = 'b1',
}) => {
  'id': id,
  'type': type,
  'status': status,
  'title': 'Booking confirmed',
  'body': 'Test Hotel confirmed your booking for Main Hall.',
  'bookingId': bookingId,
  'hotelId': 'h1',
  'hotelApplicationId': null,
  'readAt': status == 'READ' ? '2026-09-07T00:00:00.000Z' : null,
  'createdAt': '2026-09-07T00:00:00.000Z',
};

Map<String, dynamic> _bookingJson() => {
  'id': 'b1',
  'hotelId': 'h1',
  'hallId': 'hall-1',
  'hotel': {'id': 'h1', 'name': 'Test Hotel'},
  'hall': {
    'id': 'hall-1',
    'name': 'Main Hall',
    'bookingTerms': {
      'rentAmountCents': 10000,
      'rentDurationHours': 24,
      'advancePaymentPercent': 30,
      'customerServiceNumber': '+15550001111',
      'paymentReceivingNumber': '+15550002222',
    },
  },
  'startsAt': '2027-01-01T06:00:00.000Z',
  'endsAt': '2027-01-01T14:00:00.000Z',
  'numberOfGuests': 10,
  'eventType': 'WEDDING',
  'status': 'CONFIRMED',
  'paymentStatus': 'PAID',
  'pricing': {'totalRentCents': 10000, 'advancePercent': 30, 'requiredAdvanceCents': 3000},
  'payment': {},
  'createdAt': '2027-01-01T00:00:00.000Z',
  'review': null,
};

Widget _wrap(Future<http.Response> Function(http.Request) handler) {
  final apiClient = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider(create: (_) => NotificationController(NotificationRepository(apiClient))),
    ],
    child: const MaterialApp(home: NotificationCenterScreen()),
  );
}

void main() {
  testWidgets('renders the list with an unread indicator', (tester) async {
    await tester.pumpWidget(
      _wrap((request) async {
        if (request.url.path.endsWith('/notifications') && request.method == 'GET') {
          return _envelope(
            [_notificationJson(), _notificationJson(id: 'n2', status: 'READ')],
            pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
          );
        }
        if (request.url.path.endsWith('/unread-count')) return _envelope({'count': 1});
        return _envelope({});
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('Booking confirmed'), findsNWidgets(2));
    expect(find.text('No notifications yet'), findsNothing);
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
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('tapping an unread notification marks it read and navigates to Booking Detail', (tester) async {
    var markedRead = false;
    await tester.pumpWidget(
      _wrap((request) async {
        if (request.url.path.endsWith('/notifications') && request.method == 'GET') {
          return _envelope(
            [_notificationJson()],
            pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
          );
        }
        if (request.url.path.endsWith('/unread-count')) return _envelope({'count': 1});
        if (request.url.path.endsWith('/n1/read') && request.method == 'POST') {
          markedRead = true;
          return _envelope(_notificationJson(status: 'READ'));
        }
        if (request.url.path.endsWith('/bookings/b1')) return _envelope(_bookingJson());
        return _envelope({});
      }),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Booking confirmed'));
    await tester.pumpAndSettle();

    expect(markedRead, true);
    expect(find.byType(BookingDetailScreen), findsOneWidget);
  });

  testWidgets('Mark all read clears every unread indicator', (tester) async {
    var markedAllRead = false;
    await tester.pumpWidget(
      _wrap((request) async {
        if (request.url.path.endsWith('/notifications') && request.method == 'GET') {
          return _envelope(
            [_notificationJson()],
            pagination: {'limit': 20, 'hasNext': false, 'nextCursor': null},
          );
        }
        if (request.url.path.endsWith('/unread-count')) return _envelope({'count': markedAllRead ? 0 : 1});
        if (request.url.path.endsWith('/read-all')) {
          markedAllRead = true;
          return _envelope(null);
        }
        return _envelope({});
      }),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(markedAllRead, true);
  });
}
