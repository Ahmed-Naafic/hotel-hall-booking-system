import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_details_screen.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_form_screen.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_list_screen.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

http.Response _pageResponse(List<Map<String, dynamic>> halls, {bool hasNext = false}) => http.Response(
      jsonEncode({
        'status': 'success',
        'message': 'ok',
        'data': halls,
        'pagination': {'page': 1, 'limit': 20, 'total': halls.length, 'hasNext': hasNext, 'hasPrevious': false},
      }),
      200,
    );

Map<String, dynamic> _hall({String id = 'hall-1'}) => {
      'id': id,
      'hotelId': 'h1',
      'profileData': {'name': 'The Ivory Room'},
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

Widget _wrap(Future<http.Response> Function(http.Request) handler) {
  final client = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return Provider<ApiClient>.value(
    value: client,
    child: const MaterialApp(home: HallListScreen(hotelId: 'h1')),
  );
}

void main() {
  // Navigating into HallFormScreen (structured fields + Hall Photos
  // placeholder + Additional Information) needs more vertical space than
  // the default 800x600 test surface to keep its submit button tappable.
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('shows a loading indicator, then the empty state with "No halls yet" / "Create Hall"', (tester) async {
    await tester.pumpWidget(_wrap((r) async => _pageResponse([])));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('No halls yet'), findsOneWidget);
    expect(find.text('Create Hall'), findsWidgets);
  });

  testWidgets('shows Hall tiles on success', (tester) async {
    await tester.pumpWidget(_wrap((r) async => _pageResponse([_hall()])));
    await tester.pumpAndSettle();

    expect(find.text('The Ivory Room'), findsOneWidget);
  });

  testWidgets('shows an error state with retry on API failure', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(_wrap((r) async {
      callCount += 1;
      if (callCount == 1) return errorResponse('NOT_FOUND', "hotelId doesn't exist.", 404);
      return _pageResponse([_hall()]);
    }));
    await tester.pumpAndSettle();

    expect(find.text("hotelId doesn't exist."), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('The Ivory Room'), findsOneWidget);
  });

  testWidgets('tapping a Hall navigates to HallDetailsScreen', (tester) async {
    await tester.pumpWidget(_wrap((r) async {
      if (r.url.path.endsWith('/halls/hall-1')) return successResponse(_hall());
      return _pageResponse([_hall()]);
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.text('The Ivory Room'));
    await tester.pumpAndSettle();

    expect(find.byType(HallDetailsScreen), findsOneWidget);
  });

  testWidgets('tapping "Create Hall" from the empty state navigates to HallFormScreen', (tester) async {
    await tester.pumpWidget(_wrap((r) async => _pageResponse([])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Hall').first);
    await tester.pumpAndSettle();

    expect(find.byType(HallFormScreen), findsOneWidget);
  });

  testWidgets('creating a Hall shows a success snackbar and refreshes the list', (tester) async {
    var listCallCount = 0;
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'POST') return successResponse(_hall(), status: 201);
      listCallCount += 1;
      return _pageResponse(listCallCount == 1 ? [] : [_hall()]);
    }));
    await tester.pumpAndSettle();
    expect(find.text('No halls yet'), findsOneWidget);

    await tester.tap(find.text('Create Hall').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Hall Name'), 'The Ivory Room');
    await tester.enterText(find.widgetWithText(TextFormField, 'Capacity'), '80');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Hall'));
    await tester.pumpAndSettle();

    expect(find.text('Hall created.'), findsOneWidget);
    expect(find.text('The Ivory Room'), findsOneWidget);
  });
}
