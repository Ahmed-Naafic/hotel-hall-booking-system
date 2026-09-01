import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_details_screen.dart';
import 'package:manager_mobile/features/halls/presentation/screens/hall_form_screen.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

Map<String, dynamic> _hallJson({Map<String, dynamic>? profileData}) => {
      'id': 'hall-1',
      'hotelId': 'h1',
      'profileData': profileData,
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

Widget _wrap(Future<http.Response> Function(http.Request) handler) {
  final client = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return Provider<ApiClient>.value(
    value: client,
    child: const MaterialApp(home: HallDetailsScreen(hotelId: 'h1', hallId: 'hall-1')),
  );
}

void main() {
  // The edit action navigates into HallFormScreen (structured fields + Hall
  // Photos placeholder + Additional Information), taller than the default
  // 800x600 test surface, which would leave its submit button off-screen.
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('shows a loading indicator, then the Hall\'s profile fields', (tester) async {
    await tester.pumpWidget(_wrap((r) async => successResponse(_hallJson(profileData: {'name': 'The Ivory Room', 'capacity': '200'}))));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('The Ivory Room'), findsWidgets);
    expect(find.text('Capacity'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
  });

  testWidgets('shows "no profile information" for an empty Hall, never invented content', (tester) async {
    await tester.pumpWidget(_wrap((r) async => successResponse(_hallJson())));
    await tester.pumpAndSettle();

    expect(find.text('No profile information yet.'), findsOneWidget);
  });

  testWidgets('shows an error state with retry for a nonexistent/not-owned Hall (404)', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(_wrap((r) async {
      callCount += 1;
      if (callCount == 1) return errorResponse('NOT_FOUND', 'Hall not found.', 404);
      return successResponse(_hallJson(profileData: {'name': 'Recovered'}));
    }));
    await tester.pumpAndSettle();

    expect(find.text('Hall not found.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered'), findsWidgets);
  });

  testWidgets('the edit action navigates to HallFormScreen pre-filled with the Hall', (tester) async {
    await tester.pumpWidget(_wrap((r) async => successResponse(_hallJson(profileData: {'name': 'The Ivory Room'}))));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(HallFormScreen), findsOneWidget);
    expect(find.text('The Ivory Room'), findsWidgets);
  });

  testWidgets('saving an edit shows a success snackbar and returns to the refreshed details', (tester) async {
    // A stateful mock: the subsequent GET (details reload) reflects the
    // earlier PATCH, the same way a real server would persist it.
    var currentName = 'The Ivory Room';
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'PATCH') {
        currentName = 'Renamed';
        return successResponse(_hallJson(profileData: {'name': currentName, 'capacity': 80}));
      }
      return successResponse(_hallJson(profileData: {'name': currentName, 'capacity': 80}));
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Hall updated.'), findsOneWidget);
    expect(find.text('Renamed'), findsWidgets);
  });
}
