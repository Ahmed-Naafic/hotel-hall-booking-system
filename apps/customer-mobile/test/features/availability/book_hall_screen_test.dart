import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:customer_mobile/features/availability/presentation/screens/book_hall_screen.dart';
import 'package:customer_mobile/features/discovery/data/discovery_models.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

final _hall = HallSummary(id: 'hall-1', hotelId: 'h1', profileData: const {'name': 'The Ivory Room'});

Widget _wrap(Future<http.Response> Function(http.Request) handler) {
  final client = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return Provider<ApiClient>.value(
    value: client,
    child: MaterialApp(home: BookHallScreen(hall: _hall)),
  );
}

void main() {
  testWidgets('shows a loading indicator, then the day\'s busy periods', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'GET') {
        return successResponse({
          'busyPeriods': [
            {'start': '2026-09-10T07:00:00.000Z', 'end': '2026-09-10T11:00:00.000Z'},
          ],
        });
      }
      return successResponse({'available': true});
    }));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.textContaining('Busy'), findsOneWidget);
  });

  testWidgets('a day with no busy periods shows "No busy periods on this date."', (tester) async {
    await tester.pumpWidget(_wrap((r) async => successResponse({'busyPeriods': []})));
    await tester.pumpAndSettle();

    expect(find.text('No busy periods on this date.'), findsOneWidget);
  });

  testWidgets('submitting a free period creates a booking and shows its price', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'GET') return successResponse({'busyPeriods': []});
      if (r.url.path.endsWith('/availability/check')) return successResponse({'available': true});
      return successResponse({
        'id': 'booking-1', 'status': 'PENDING', 'paymentStatus': 'UNPAID',
        'pricing': {'totalRentCents': 50000, 'requiredAdvanceCents': 10000},
      });
    }));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Request Booking'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Request Booking'));
    await tester.pumpAndSettle();

    expect(find.text('Booking requested'), findsOneWidget);
    expect(find.textContaining('Advance required: \$100.00'), findsOneWidget);
  });

  testWidgets(
    'submitting a period the backend now rejects shows "no longer available" and stays on this screen (rule 12/13)',
    (tester) async {
      await tester.pumpWidget(_wrap((r) async {
        if (r.method == 'GET') return successResponse({'busyPeriods': []});
        return successResponse({'available': false});
      }));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Request Booking'));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Request Booking'));
      await tester.pumpAndSettle();

      expect(find.text('This time is no longer available — please choose another.'), findsOneWidget);
      expect(find.byType(BookHallScreen), findsOneWidget);
    },
  );

  testWidgets('a backend failure on submit surfaces the server message, never a silent failure', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'GET') return successResponse({'busyPeriods': []});
      return errorResponse('AUTHENTICATION_ERROR', 'Please log in again.', 401);
    }));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Request Booking'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Request Booking'));
    await tester.pumpAndSettle();

    expect(find.text('Please log in again.'), findsOneWidget);
  });
}
