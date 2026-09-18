import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/core/presentation/booking_list_tile.dart';
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

/// A lifecycle action responds with the single updated Booking, not a list —
/// the sheet re-renders itself from this rather than waiting on a refetch.
http.Response _objectEnvelope(Map<String, dynamic> data) => http.Response(
  jsonEncode({'status': 'success', 'message': 'ok', 'data': data}),
  200,
);

Map<String, dynamic> _bookingJson({
  String id = 'b1',
  required String status,
  required String paymentStatus,
  int? reportedAmountCents,
  Map<String, dynamic>? customer,
  Map<String, dynamic>? hall,
  String startsAt = '2027-01-01T00:00:00.000Z',
  String endsAt = '2027-01-02T00:00:00.000Z',
}) => {
  'id': id,
  'hallId': 'hall-1',
  'startsAt': startsAt,
  'endsAt': endsAt,
  'numberOfGuests': 10,
  'eventType': 'WEDDING',
  'status': status,
  'paymentStatus': paymentStatus,
  'pricing': {'totalRentCents': 10000, 'requiredAdvanceCents': 3000},
  'payment': {'reportedAmountCents': reportedAmountCents},
  if (customer != null) 'customer': customer,
  if (hall != null) 'hall': hall,
};

Widget _wrap(ApiClient apiClient) {
  return MultiProvider(
    providers: [Provider<ApiClient>.value(value: apiClient)],
    child: const MaterialApp(
      home: BookingsComingSoonScreen(hotelId: 'hotel-1', active: true),
    ),
  );
}

/// Every action button now lives inside the detail sheet opened by tapping
/// a row, not inline in the list (the mockup's own Bookings screen shows
/// no inline actions at all) — this taps the one row the fixture always
/// seeds to get there. Scoped to `BookingListTile`'s own `InkWell`, not
/// `.first` on the whole tree — the filter chips above the list are also
/// `InkWell`-based and would otherwise win that race.
Future<void> _openFirstBookingDetail(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: find.byType(BookingListTile), matching: find.byType(InkWell)).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the empty Hotel setup state when no Hotel is available', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BookingsComingSoonScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Set up your Hotel'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('shows the All/Confirmed/Pending filter chips with real counts', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient(
        (_) async => _paginatedEnvelope([
          _bookingJson(id: 'b1', status: 'CONFIRMED', paymentStatus: 'PAID'),
          _bookingJson(id: 'b2', status: 'PENDING', paymentStatus: 'UNPAID'),
          _bookingJson(id: 'b3', status: 'PENDING', paymentStatus: 'UNPAID'),
        ]),
      ),
      baseUrl: 'http://test/api/v1',
    );
    await tester.pumpWidget(_wrap(apiClient));
    await tester.pumpAndSettle();

    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('Confirmed (1)'), findsOneWidget);
    expect(find.text('Pending (2)'), findsOneWidget);
  });

  testWidgets('tapping the Pending chip narrows the list to Pending Bookings only', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient(
        (_) async => _paginatedEnvelope([
          _bookingJson(id: 'b1', status: 'CONFIRMED', paymentStatus: 'PAID', customer: {'id': 'c1', 'fullName': 'Amina Yusuf'}),
          _bookingJson(id: 'b2', status: 'PENDING', paymentStatus: 'UNPAID', customer: {'id': 'c2', 'fullName': 'Deeqa Ali'}),
        ]),
      ),
      baseUrl: 'http://test/api/v1',
    );
    await tester.pumpWidget(_wrap(apiClient));
    await tester.pumpAndSettle();

    expect(find.text('Amina Yusuf'), findsOneWidget);
    expect(find.text('Deeqa Ali'), findsOneWidget);

    await tester.tap(find.text('Pending (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Amina Yusuf'), findsNothing);
    expect(find.text('Deeqa Ali'), findsOneWidget);
  });

  testWidgets('searching filters by Customer name, mobile, or Hall name', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient(
        (_) async => _paginatedEnvelope([
          _bookingJson(
            id: 'b1',
            status: 'PENDING',
            paymentStatus: 'UNPAID',
            customer: {'id': 'c1', 'fullName': 'Amina Yusuf'},
            hall: {'id': 'hall-1', 'name': 'Grand Ballroom'},
          ),
          _bookingJson(
            id: 'b2',
            status: 'PENDING',
            paymentStatus: 'UNPAID',
            customer: {'id': 'c2', 'fullName': 'Deeqa Ali'},
            hall: {'id': 'hall-2', 'name': 'Garden Room'},
          ),
        ]),
      ),
      baseUrl: 'http://test/api/v1',
    );
    await tester.pumpWidget(_wrap(apiClient));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ballroom');
    await tester.pumpAndSettle();

    expect(find.text('Amina Yusuf'), findsOneWidget);
    expect(find.text('Deeqa Ali'), findsNothing);
  });

  testWidgets('tapping a row opens the detail sheet with the Hall name and status', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient(
        (_) async => _paginatedEnvelope([
          _bookingJson(
            status: 'CONFIRMED',
            paymentStatus: 'PAID',
            customer: {'id': 'c1', 'fullName': 'Amina Yusuf'},
            hall: {'id': 'hall-1', 'name': 'Grand Ballroom'},
          ),
        ]),
      ),
      baseUrl: 'http://test/api/v1',
    );
    await tester.pumpWidget(_wrap(apiClient));
    await tester.pumpAndSettle();

    await _openFirstBookingDetail(tester);

    expect(find.text('Grand Ballroom'), findsOneWidget);
    expect(find.text('Confirmed'), findsWidgets);
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
      await _openFirstBookingDetail(tester);

      expect(find.textContaining('45.00'), findsOneWidget);
      expect(find.textContaining('30.00'), findsOneWidget);
      expect(find.text('Verify Payment'), findsOneWidget);
      expect(find.text('Reject Payment'), findsOneWidget);
    },
  );

  testWidgets(
    "shows the Customer's real Full Name and Mobile Number (BDR-018)",
    (tester) async {
      final apiClient = ApiClient(
        httpClient: MockClient(
          (_) async => _paginatedEnvelope([
            _bookingJson(
              status: 'PENDING',
              paymentStatus: 'UNPAID',
              customer: {'id': 'cust-1', 'fullName': 'Amina Yusuf', 'mobileNumber': '+15551234567'},
            ),
          ]),
        ),
        baseUrl: 'http://test/api/v1',
      );
      await tester.pumpWidget(_wrap(apiClient));
      await tester.pumpAndSettle();
      await _openFirstBookingDetail(tester);

      expect(find.textContaining('Amina Yusuf'), findsWidgets);
      expect(find.textContaining('+15551234567'), findsOneWidget);
    },
  );

  testWidgets(
    'shows no customer line at all (never a fake name) when the Customer has none on file',
    (tester) async {
      final apiClient = ApiClient(
        httpClient: MockClient(
          (_) async => _paginatedEnvelope([
            _bookingJson(
              status: 'PENDING',
              paymentStatus: 'UNPAID',
              customer: {'id': 'cust-1', 'fullName': null, 'mobileNumber': '+15551234567'},
            ),
          ]),
        ),
        baseUrl: 'http://test/api/v1',
      );
      await tester.pumpWidget(_wrap(apiClient));
      await tester.pumpAndSettle();
      await _openFirstBookingDetail(tester);

      expect(find.textContaining('null'), findsNothing);
      // Appears twice by design: the row's own display-name fallback (no
      // Full Name on file) and the detail sheet's customer line.
      expect(find.textContaining('+15551234567'), findsWidgets);
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
      await _openFirstBookingDetail(tester);

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
            return _objectEnvelope(
              _bookingJson(status: 'PENDING', paymentStatus: 'PAID'),
            );
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
      await _openFirstBookingDetail(tester);

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
            return _objectEnvelope(
              _bookingJson(status: 'PENDING', paymentStatus: 'PAID'),
            );
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
      await _openFirstBookingDetail(tester);

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
      await _openFirstBookingDetail(tester);

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
            return _objectEnvelope(
              _bookingJson(status: 'PENDING', paymentStatus: 'PAID'),
            );
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
      await _openFirstBookingDetail(tester);

      await tester.tap(find.text('Verify Payment'));
      await tester.pump();

      expect(find.text('Verify Payment'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'verifying a payment reveals Confirm on the still-open sheet, with no manual refresh',
    (tester) async {
      final apiClient = ApiClient(
        httpClient: MockClient((request) async {
          if (request.method == 'POST' && request.url.path.endsWith('/payment-verification')) {
            return _objectEnvelope(
              _bookingJson(status: 'PENDING', paymentStatus: 'PAID'),
            );
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
      await _openFirstBookingDetail(tester);

      expect(find.text('Confirm'), findsNothing);

      await tester.tap(find.text('Verify Payment'));
      await tester.pumpAndSettle();

      // The sheet stays open and re-renders from the verified Booking — it
      // used to keep showing the pre-verification one until reopened.
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Verify Payment'), findsNothing);
    },
  );

  // The backend refuses completion before `endsAt` and no-show before
  // `startsAt` with a 422, so offering either button early guarantees a
  // failed tap.
  testWidgets(
    'Complete and No-show stay disabled until a CONFIRMED Booking starts and ends',
    (tester) async {
      final apiClient = ApiClient(
        httpClient: MockClient(
          (_) async => _paginatedEnvelope([
            _bookingJson(status: 'CONFIRMED', paymentStatus: 'PAID'),
          ]),
        ),
        baseUrl: 'http://test/api/v1',
      );
      await tester.pumpWidget(_wrap(apiClient));
      await tester.pumpAndSettle();
      await _openFirstBookingDetail(tester);

      expect(
        tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Complete')).onPressed,
        isNull,
      );
      expect(
        tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'No-show')).onPressed,
        isNull,
      );
      expect(
        find.text('No-show can be marked once this Booking starts, and Complete once it ends.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Complete is enabled once a CONFIRMED Booking has ended', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient(
        (_) async => _paginatedEnvelope([
          _bookingJson(
            status: 'CONFIRMED',
            paymentStatus: 'PAID',
            startsAt: '2020-01-01T00:00:00.000Z',
            endsAt: '2020-01-02T00:00:00.000Z',
          ),
        ]),
      ),
      baseUrl: 'http://test/api/v1',
    );
    await tester.pumpWidget(_wrap(apiClient));
    await tester.pumpAndSettle();
    await _openFirstBookingDetail(tester);

    expect(
      tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Complete')).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'No-show')).onPressed,
      isNotNull,
    );
    expect(find.textContaining('once this Booking'), findsNothing);
  });

  testWidgets('confirming a paid Booking closes the detail sheet', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/confirmation')) {
          return _objectEnvelope(
            _bookingJson(status: 'CONFIRMED', paymentStatus: 'PAID'),
          );
        }
        return _paginatedEnvelope([
          _bookingJson(status: 'PENDING', paymentStatus: 'PAID'),
        ]);
      }),
      baseUrl: 'http://test/api/v1',
    );
    await tester.pumpWidget(_wrap(apiClient));
    await tester.pumpAndSettle();
    await _openFirstBookingDetail(tester);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm'), findsNothing);
    expect(find.byType(BookingListTile), findsOneWidget);
  });
}
