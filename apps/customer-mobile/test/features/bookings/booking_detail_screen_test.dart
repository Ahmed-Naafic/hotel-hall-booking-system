import 'dart:convert';

import 'package:customer_mobile/features/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

http.Response _envelope(dynamic data) => http.Response(
  jsonEncode({'status': 'success', 'message': 'ok', 'data': data}),
  200,
);

Map<String, dynamic> _bookingJson({
  required String status,
  Map<String, dynamic>? review,
}) => {
  'id': 'b1',
  'hotelId': 'hotel-1',
  'hallId': 'hall-1',
  'hotel': {'id': 'hotel-1', 'name': 'Test Hotel'},
  'hall': {
    'id': 'hall-1',
    'name': 'Test Hall',
    'bookingTerms': {
      'rentAmountCents': 10000,
      'rentDurationHours': 24,
      'advancePaymentPercent': 30,
      'customerServiceNumber': '+15550001111',
      'paymentReceivingNumber': '+15550002222',
    },
  },
  'startsAt': '2026-01-01T00:00:00.000Z',
  'endsAt': '2026-01-02T00:00:00.000Z',
  'numberOfGuests': 10,
  'eventType': 'OTHER',
  'status': status,
  'paymentStatus': 'PAID',
  'pricing': {
    'totalRentCents': 10000,
    'advancePercent': 30,
    'requiredAdvanceCents': 3000,
  },
  'payment': {},
  'createdAt': '2026-01-01T00:00:00.000Z',
  'review': review,
};

Widget _wrap(ApiClient apiClient) {
  return MultiProvider(
    providers: [Provider<ApiClient>.value(value: apiClient)],
    child: const MaterialApp(home: BookingDetailScreen(bookingId: 'b1')),
  );
}

/// The Booking Details screen is a single long scrollable list — the
/// action buttons at its end are below the fold in the test viewport's
/// default size and, being inside a (lazily-built) `SliverList`, have no
/// Element at all until scrolled into view. `scrollUntilVisible` mirrors
/// what a real Customer does (scroll down) rather than assuming eager
/// building.
Future<void> _scrollToFinder(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a COMPLETED Booking without a review shows the Leave a Review button', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient((_) async => _envelope(_bookingJson(status: 'COMPLETED'))),
      baseUrl: 'http://test/api/v1',
    );
    await tester.pumpWidget(_wrap(apiClient));
    await tester.pumpAndSettle();
    await _scrollToFinder(tester, find.text('Leave a Review'));

    expect(find.text('Leave a Review'), findsOneWidget);
    expect(find.text('YOUR REVIEW'), findsNothing);
  });

  testWidgets('a COMPLETED Booking that already has a review shows it, not the button', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient(
        (_) async => _envelope(
          _bookingJson(
            status: 'COMPLETED',
            review: {
              'id': 'rev1',
              'rating': 4,
              'text': 'Great stay',
              'createdAt': '2026-01-03T00:00:00.000Z',
            },
          ),
        ),
      ),
      baseUrl: 'http://test/api/v1',
    );
    await tester.pumpWidget(_wrap(apiClient));
    await tester.pumpAndSettle();
    await _scrollToFinder(tester, find.text('YOUR REVIEW'));

    expect(find.text('YOUR REVIEW'), findsOneWidget);
    expect(find.text('Great stay'), findsOneWidget);
    expect(find.text('Leave a Review'), findsNothing);
  });

  testWidgets('a non-COMPLETED Booking shows neither the button nor a review section', (tester) async {
    final apiClient = ApiClient(
      httpClient: MockClient((_) async => _envelope(_bookingJson(status: 'CONFIRMED'))),
      baseUrl: 'http://test/api/v1',
    );
    await tester.pumpWidget(_wrap(apiClient));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Cancel Booking'), 200, scrollable: find.byType(Scrollable));
    await tester.pumpAndSettle();

    expect(find.text('Leave a Review'), findsNothing);
    expect(find.text('YOUR REVIEW'), findsNothing);
  });

  testWidgets('submitting a review updates the screen to show it', (tester) async {
    var submitted = false;
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/review')) {
          submitted = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return _envelope(
            _bookingJson(
              status: 'COMPLETED',
              review: {
                'id': 'rev1',
                'rating': body['rating'],
                'text': body['text'],
                'createdAt': '2026-01-03T00:00:00.000Z',
              },
            ),
          );
        }
        return _envelope(_bookingJson(status: 'COMPLETED'));
      }),
      baseUrl: 'http://test/api/v1',
    );
    await tester.pumpWidget(_wrap(apiClient));
    await tester.pumpAndSettle();
    await _scrollToFinder(tester, find.text('Leave a Review'));

    await tester.tap(find.text('Leave a Review'));
    // Not pumpAndSettle: the dialog's comment TextField has a blinking
    // caret timer that never naturally stops, which is a well-known cause
    // of pumpAndSettle hanging — bounded pumps sidestep it, the same
    // workaround already used elsewhere in this suite for other
    // indefinite-animation cases.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap the 4th star (1-indexed) to set rating=4.
    final starButtons = find.byIcon(Icons.star_outline_rounded);
    await tester.tap(starButtons.at(3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Submit'));
    // Not pumpAndSettle: submitting shows a SnackBar with a real-world
    // default duration, which keeps scheduling frames well past what
    // pumpAndSettle's internal attempt budget allows — the same
    // known class of hang as an indefinite platform-channel wait,
    // worked around the same way (bounded pumps) elsewhere in this suite.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(submitted, true);
    expect(find.text('YOUR REVIEW'), findsOneWidget);
    expect(find.text('Leave a Review'), findsNothing);
  });
}
