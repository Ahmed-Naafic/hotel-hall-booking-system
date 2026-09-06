import 'dart:convert';

import 'package:customer_mobile/core/pending_action_controller.dart';
import 'package:customer_mobile/features/availability/presentation/screens/book_hall_screen.dart';
import 'package:customer_mobile/features/discovery/data/discovery_models.dart';
import 'package:customer_mobile/features/discovery/presentation/discover_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

/// Covers a gap found during manual testing: after requesting a Booking and
/// choosing "I'll pay later" (or reporting payment), Hall Detail gave the
/// Customer no acknowledgement at all that anything happened — the Booking
/// was created correctly, but the screen just silently returned, which
/// read as if nothing had happened. `HallDetailScreen._book()` now shows a
/// confirmation SnackBar once `BookHallScreen` reports a Booking was made.
final _hall = HallSummary.fromJson({
  'id': 'hall-1',
  'hotelId': 'h1',
  'profileData': {'name': 'The Ivory Room'},
  'bookingTerms': {
    'rentAmountCents': 10000,
    'rentDurationHours': 24,
    'advancePaymentPercent': 30,
    'customerServiceNumber': '+15550001111',
    'paymentReceivingNumber': '+15550002222',
  },
});

http.Response _envelope(dynamic data) => http.Response(
  jsonEncode({'status': 'success', 'message': 'ok', 'data': data}),
  200,
);

Widget _wrap({required AuthController auth, required MockClient httpClient}) {
  final apiClient = ApiClient(httpClient: httpClient, baseUrl: 'http://test/api/v1');
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider(create: (_) => PendingActionController()),
    ],
    child: MaterialApp(home: HallDetailScreen(hall: _hall)),
  );
}

Future<AuthController> _authenticatedVerifiedController() async {
  final sessionStore = SessionStore(storage: InMemoryTokenStorage());
  final client = ApiClient(
    httpClient: MockClient(
      (r) async => successResponse({
        'accessToken': 'a',
        'refreshToken': 'b',
        'user': testUser(isVerified: true),
      }),
    ),
    baseUrl: 'http://test/api/v1',
    accessTokenProvider: () => sessionStore.accessToken,
  );
  final controller = AuthController(repository: AuthRepository(client), sessionStore: sessionStore);
  await controller.login(mobileNumber: '+15551234567', password: 'password123');
  return controller;
}

Map<String, dynamic> _bookingJson() => {
  'id': 'b1',
  'hotelId': 'h1',
  'hallId': 'hall-1',
  'hotel': {'id': 'h1', 'name': 'Test Hotel'},
  'hall': {
    'id': 'hall-1',
    'name': 'The Ivory Room',
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
  'status': 'PENDING',
  'paymentStatus': 'UNPAID',
  'pricing': {'totalRentCents': 10000, 'advancePercent': 30, 'requiredAdvanceCents': 3000},
  'payment': {},
  'createdAt': '2027-01-01T00:00:00.000Z',
  'review': null,
};

void main() {
  testWidgets(
    'choosing "I\'ll pay later" after a successful booking shows a confirmation SnackBar on Hall Detail',
    (tester) async {
      final auth = await _authenticatedVerifiedController();
      final httpClient = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/availability') && request.method == 'GET') {
          return _envelope({'busyPeriods': []});
        }
        if (path.endsWith('/availability/check')) {
          return _envelope({'available': true});
        }
        if (path == '/api/v1/bookings' && request.method == 'POST') {
          return _envelope(_bookingJson());
        }
        return _envelope({});
      });

      await tester.pumpWidget(_wrap(auth: auth, httpClient: httpClient));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Book Hall'));
      await tester.pumpAndSettle();
      expect(find.byType(BookHallScreen), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Request Booking'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Request Booking'));
      await tester.pumpAndSettle();

      expect(find.text('Booking requested'), findsOneWidget);
      await tester.tap(find.text("I'll pay later"));
      await tester.pumpAndSettle();

      expect(find.byType(BookHallScreen), findsNothing);
      expect(
        find.text('Booking requested. Track its status and payment from My Bookings.'),
        findsOneWidget,
      );
    },
  );
}
