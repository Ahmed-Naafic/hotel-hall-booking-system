import 'dart:convert';

import 'package:customer_mobile/features/discovery/presentation/discover_screen.dart';
import 'package:customer_mobile/features/favorites/application/favorites_controller.dart';
import 'package:customer_mobile/features/favorites/data/favorites_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

/// Covers a gap found during a data-refresh audit: Hotel Detail fetched its
/// Hotel/Halls/reviews exactly once in `initState` and never again, so a
/// Customer who booked a Hall (or anything else that could change while
/// looking at its own detail screen) and popped back here saw stale data
/// until leaving and re-entering the whole screen. `_HallCard` now awaits
/// its own push into Hall Detail and calls back into Hotel Detail's
/// `onHallReturned` on every return, unconditionally — this test proves
/// that wiring fires, not any particular booking outcome.
http.Response _envelope(dynamic data) => http.Response(
  jsonEncode({'status': 'success', 'message': 'ok', 'data': data}),
  200,
);

Map<String, dynamic> _hotelJson() => {
  'id': 'h1',
  'profileData': {'name': 'Test Hotel'},
  'logo': null,
  'photos': [],
  'reviewSummary': {'average': null, 'count': 0},
};

Map<String, dynamic> _hallJson() => {
  'id': 'hall-1',
  'hotelId': 'h1',
  'profileData': {'name': 'The Ivory Room'},
  'photos': [],
  'bookingTerms': {
    'rentAmountCents': 10000,
    'rentDurationHours': 24,
    'advancePaymentPercent': 30,
    'customerServiceNumber': '+15550001111',
    'paymentReceivingNumber': '+15550002222',
  },
};

Widget _wrap(MockClient httpClient) {
  final apiClient = ApiClient(httpClient: httpClient, baseUrl: 'http://test/api/v1');
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider(create: (_) => FavoritesController(FavoritesRepository(apiClient))),
    ],
    child: const MaterialApp(home: HotelDetailScreen(hotelId: 'h1')),
  );
}

void main() {
  testWidgets(
    'returning from a Hall\'s own detail screen refreshes Hotel Detail\'s Hotel/Halls/reviews fetch',
    (tester) async {
      var hotelFetchCount = 0;
      var hallsFetchCount = 0;
      var reviewsFetchCount = 0;
      final httpClient = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/hotels/public/h1')) {
          hotelFetchCount += 1;
          return _envelope(_hotelJson());
        }
        if (path.endsWith('/halls')) {
          hallsFetchCount += 1;
          return _envelope([_hallJson()]);
        }
        if (path.endsWith('/hotels/h1/reviews')) {
          reviewsFetchCount += 1;
          return _envelope([]);
        }
        if (path.endsWith('/favorites/hotels')) {
          return _envelope(<String>[]);
        }
        return _envelope([]);
      });

      await tester.pumpWidget(_wrap(httpClient));
      await tester.pumpAndSettle();

      expect(hotelFetchCount, 1);
      expect(hallsFetchCount, 1);
      expect(reviewsFetchCount, 1);

      await tester.scrollUntilVisible(
        find.text('The Ivory Room'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('The Ivory Room'));
      await tester.pumpAndSettle();
      expect(find.byType(HallDetailScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(HallDetailScreen), findsNothing);
      expect(hotelFetchCount, 2, reason: 'Hotel Detail must refetch the Hotel on return from Hall Detail');
      expect(hallsFetchCount, 2, reason: 'Hotel Detail must refetch its Halls list on return from Hall Detail');
      expect(reviewsFetchCount, 2, reason: 'Hotel Detail must refresh its review summary on return from Hall Detail');
    },
  );
}
