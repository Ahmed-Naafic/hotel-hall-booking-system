import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/availability/presentation/screens/block_form_screen.dart';
import 'package:manager_mobile/features/availability/presentation/screens/hall_availability_screen.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

Map<String, dynamic> _blockJson({String id = 'block-1'}) => {
      'id': id,
      'hallId': 'hall-1',
      'startsAt': '2026-09-10T07:00:00.000Z',
      'endsAt': '2026-09-10T11:00:00.000Z',
      'reason': 'Maintenance',
      'createdByUserId': 'u1',
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

http.Response _listResponse(List<Map<String, dynamic>> blocks) => http.Response(
      jsonEncode({'status': 'success', 'message': 'ok', 'data': blocks}),
      200,
    );

Widget _wrap(Future<http.Response> Function(http.Request) handler) {
  final client = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return Provider<ApiClient>.value(
    value: client,
    child: const MaterialApp(home: HallAvailabilityScreen(hotelId: 'h1', hallId: 'hall-1')),
  );
}

void main() {
  // BlockFormScreen (date/time pickers + reason field) is taller than the
  // default 800x600 test surface — enlarge it, matching the established
  // pattern for every other form screen in this app.
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2000);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('shows a loading indicator, then the empty state with "No blocks"', (tester) async {
    await tester.pumpWidget(_wrap((r) async => _listResponse([])));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('No blocks'), findsOneWidget);
  });

  testWidgets('shows block tiles on success', (tester) async {
    await tester.pumpWidget(_wrap((r) async => _listResponse([_blockJson()])));
    await tester.pumpAndSettle();

    expect(find.text('Maintenance'), findsOneWidget);
  });

  testWidgets('shows an error state with retry on API failure', (tester) async {
    var callCount = 0;
    await tester.pumpWidget(_wrap((r) async {
      callCount += 1;
      if (callCount == 1) return errorResponse('NOT_FOUND', 'Hall not found.', 404);
      return _listResponse([_blockJson()]);
    }));
    await tester.pumpAndSettle();

    expect(find.text('Hall not found.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Maintenance'), findsWidgets);
  });

  testWidgets('tapping "Add Block" navigates to BlockFormScreen in create mode', (tester) async {
    await tester.pumpWidget(_wrap((r) async => _listResponse([])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Block'));
    await tester.pumpAndSettle();

    expect(find.byType(BlockFormScreen), findsOneWidget);
    expect(find.text('Add Block'), findsOneWidget); // AppBar title in create mode
  });

  testWidgets('tapping a block tile navigates to BlockFormScreen pre-filled for editing', (tester) async {
    await tester.pumpWidget(_wrap((r) async => _listResponse([_blockJson()])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maintenance'));
    await tester.pumpAndSettle();

    expect(find.byType(BlockFormScreen), findsOneWidget);
    expect(find.text('Edit Block'), findsOneWidget);
  });

  testWidgets('creating a block shows a success snackbar and adds it to the list', (tester) async {
    // Real backend behavior: once created, a GET for that block's own date
    // returns it too — matters here because the block's date (fixed in
    // `_blockJson()`) may differ from `selectedDate`'s default (today),
    // which correctly triggers a same-day-or-switch reload
    // (`AvailabilityController.upsert`), not just a local list append.
    var created = false;
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'POST') {
        created = true;
        return successResponse(_blockJson(), status: 201);
      }
      return _listResponse(created ? [_blockJson()] : []);
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Block'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Block'));
    await tester.pumpAndSettle();

    expect(find.text('Availability block created.'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
  });

  testWidgets('deleting a block asks for confirmation, then removes it on confirm', (tester) async {
    var deleteCalled = false;
    await tester.pumpWidget(_wrap((r) async {
      if (r.method == 'DELETE') {
        deleteCalled = true;
        return http.Response('', 204);
      }
      return _listResponse([_blockJson()]);
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete availability block?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(deleteCalled, true);
    expect(find.text('Availability block deleted.'), findsOneWidget);
    expect(find.text('No blocks'), findsOneWidget);
  });
}
