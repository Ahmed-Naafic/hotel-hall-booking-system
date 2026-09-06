import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/dashboard/presentation/screens/bookings_coming_soon_screen.dart';
import 'package:provider/provider.dart';

http.Response _paginatedEnvelope(List<Map<String, dynamic>> data) => http.Response(
  jsonEncode({
    'status': 'success',
    'message': 'ok',
    'data': data,
    'pagination': {'limit': 100, 'hasNext': false, 'nextCursor': null},
  }),
  200,
);

Map<String, dynamic> _bookingJson({
  required String status,
  required String paymentStatus,
  int? reportedAmountCents,
}) => {
  'id': 'b1',
  'hallId': 'hall-1',
  'startsAt': '2027-01-01T00:00:00.000Z',
  'endsAt': '2027-01-02T00:00:00.000Z',
  'numberOfGuests': 10,
  'eventType': 'WEDDING',
  'status': status,
  'paymentStatus': paymentStatus,
  'pricing': {'totalRentCents': 10000, 'requiredAdvanceCents': 3000},
  'payment': {'reportedAmountCents': reportedAmountCents},
};

Widget _wrap(ApiClient apiClient) {
  return MultiProvider(
    providers: [Provider<ApiClient>.value(value: apiClient)],
    child: const MaterialApp(
      home: BookingsComingSoonScreen(hotelId: 'hotel-1', active: true),
    ),
  );
}

void main() {
  testWidgets('shows the empty Hotel setup state when no Hotel is available', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BookingsComingSoonScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Set up your Hotel'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets(
    'shows the Customer-reported amount alongside the required advance when a payment report is pending review',
    (tester) async {
      final apiClient = ApiClient(
        httpClient: MockClient(
          (_) async => _paginatedEnvelope([
            _bookingJson(
              status: 'PENDING',
              paymentStatus: 'CUSTOMER_REPORTED',
              reportedAmountCents: 4500,
            ),
          ]),
        ),
        baseUrl: 'http://test/api/v1',
      );
      await tester.pumpWidget(_wrap(apiClient));
      await tester.pumpAndSettle();

      expect(find.textContaining('45.00'), findsOneWidget);
      expect(find.textContaining('30.00'), findsOneWidget);
      expect(find.text('Verify Payment'), findsOneWidget);
      expect(find.text('Reject Payment'), findsOneWidget);
    },
  );

  testWidgets(
    'does not show a reported-amount line for a Booking with no active payment report',
    (tester) async {
      final apiClient = ApiClient(
        httpClient: MockClient(
          (_) async => _paginatedEnvelope([
            _bookingJson(status: 'PENDING', paymentStatus: 'UNPAID'),
          ]),
        ),
        baseUrl: 'http://test/api/v1',
      );
      await tester.pumpWidget(_wrap(apiClient));
      await tester.pumpAndSettle();

      expect(find.textContaining('Customer reported'), findsNothing);
    },
  );

  testWidgets(
    'verifying a sufficient reported amount calls the action directly, no confirmation dialog',
    (tester) async {
      var verifyCalled = false;
      final apiClient = ApiClient(
        httpClient: MockClient((request) async {
          if (request.method == 'POST' && request.url.path.endsWith('/payment-verification')) {
            verifyCalled = true;
          }
          return _paginatedEnvelope([
            _bookingJson(
              status: 'PENDING',
              paymentStatus: 'CUSTOMER_REPORTED',
              reportedAmountCents: 3000,
            ),
          ]);
        }),
        baseUrl: 'http://test/api/v1',
      );
      await tester.pumpWidget(_wrap(apiClient));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verify Payment'));
      await tester.pumpAndSettle();

      expect(find.text('Reported amount is short'), findsNothing);
      expect(verifyCalled, true);
    },
  );

  testWidgets(
    'verifying an insufficient reported amount asks for confirmation before calling the action',
    (tester) async {
      var verifyCalled = false;
      final apiClient = ApiClient(
        httpClient: MockClient((request) async {
          if (request.method == 'POST' && request.url.path.endsWith('/payment-verification')) {
            verifyCalled = true;
          }
          return _paginatedEnvelope([
            _bookingJson(
              status: 'PENDING',
              paymentStatus: 'CUSTOMER_REPORTED',
              reportedAmountCents: 1000,
            ),
          ]);
        }),
        baseUrl: 'http://test/api/v1',
      );
      await tester.pumpWidget(_wrap(apiClient));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verify Payment'));
      await tester.pumpAndSettle();

      expect(find.text('Reported amount is short'), findsOneWidget);
      expect(verifyCalled, false, reason: 'must not call the backend before confirmation');

      await tester.tap(find.text('Verify Anyway'));
      await tester.pumpAndSettle();

      expect(verifyCalled, true);
    },
  );

  testWidgets(
    'cancelling the confirmation dialog never calls the action',
    (tester) async {
      var verifyCalled = false;
      final apiClient = ApiClient(
        httpClient: MockClient((request) async {
          if (request.method == 'POST' && request.url.path.endsWith('/payment-verification')) {
            verifyCalled = true;
          }
          return _paginatedEnvelope([
            _bookingJson(
              status: 'PENDING',
              paymentStatus: 'CUSTOMER_REPORTED',
              reportedAmountCents: 1000,
            ),
          ]);
        }),
        baseUrl: 'http://test/api/v1',
      );
      await tester.pumpWidget(_wrap(apiClient));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verify Payment'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Cancel')),
      );
      await tester.pumpAndSettle();

      expect(verifyCalled, false);
    },
  );

  testWidgets(
    'tapping an action button shows a spinner in place of its label while the request is pending, then clears it',
    (tester) async {
      final completer = Completer<void>();
      final apiClient = ApiClient(
        httpClient: MockClient((request) async {
          if (request.method == 'POST' && request.url.path.endsWith('/payment-verification')) {
            await completer.future;
          }
          return _paginatedEnvelope([
            _bookingJson(
              status: 'PENDING',
              paymentStatus: 'CUSTOMER_REPORTED',
              reportedAmountCents: 3000,
            ),
          ]);
        }),
        baseUrl: 'http://test/api/v1',
      );
      await tester.pumpWidget(_wrap(apiClient));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verify Payment'));
      await tester.pump();

      expect(find.text('Verify Payment'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
