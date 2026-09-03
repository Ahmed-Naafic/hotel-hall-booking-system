import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manager_mobile/features/availability/data/availability_models.dart';
import 'package:manager_mobile/features/availability/presentation/screens/block_form_screen.dart';
import 'package:provider/provider.dart';

import '../../test_support.dart';

Map<String, dynamic> _blockJson({
  String startsAt = '2026-09-10T07:00:00.000Z',
  String endsAt = '2026-09-10T11:00:00.000Z',
  String? reason = 'Maintenance',
}) => {
      'id': 'block-1',
      'hallId': 'hall-1',
      'startsAt': startsAt,
      'endsAt': endsAt,
      'reason': reason,
      'createdByUserId': 'u1',
      'createdAt': '2026-08-25T00:00:00.000Z',
      'updatedAt': '2026-08-25T00:00:00.000Z',
    };

Widget _wrap(Widget child, Future<http.Response> Function(http.Request) handler) {
  final client = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return Provider<ApiClient>.value(value: client, child: MaterialApp(home: child));
}

Finder _submitButton(String label) => find.widgetWithText(ElevatedButton, label);

void main() {
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 1400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  group('Create', () {
    testWidgets('sends date/startTime/endTime/reason to the create endpoint', (tester) async {
      Map<String, dynamic>? sent;
      await tester.pumpWidget(
        _wrap(
          BlockFormScreen(hotelId: 'h1', hallId: 'hall-1', initialDate: DateTime(2026, 9, 10)),
          (r) async {
            sent = {'method': r.method, 'path': r.url.path, 'body': r.body};
            return successResponse(_blockJson(), status: 201);
          },
        ),
      );

      await tester.tap(_submitButton('Create Block'));
      await tester.pumpAndSettle();

      expect(sent!['method'], 'POST');
      expect(sent!['path'], '/api/v1/hotels/h1/halls/hall-1/availability/blocks');
      final body = sent!['body'] as String;
      expect(body, contains('"date":"2026-09-10"'));
      expect(body, contains('"startTime":"09:00"'));
      expect(body, contains('"endTime":"17:00"'));
    });

    testWidgets('an omitted reason is not sent', (tester) async {
      Map<String, dynamic>? sent;
      await tester.pumpWidget(
        _wrap(
          BlockFormScreen(hotelId: 'h1', hallId: 'hall-1', initialDate: DateTime(2026, 9, 10)),
          (r) async {
            sent = {'body': r.body};
            return successResponse(_blockJson(reason: null), status: 201);
          },
        ),
      );

      await tester.tap(_submitButton('Create Block'));
      await tester.pumpAndSettle();

      expect(sent!['body'], isNot(contains('"reason"')));
    });

    testWidgets('a 409 conflict is shown inline and the form stays open', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BlockFormScreen(hotelId: 'h1', hallId: 'hall-1', initialDate: DateTime(2026, 9, 10)),
          (r) async => errorResponse('CONFLICT', 'This period conflicts with an existing availability block.', 409),
        ),
      );

      await tester.tap(_submitButton('Create Block'));
      await tester.pumpAndSettle();

      expect(find.text('This period conflicts with an existing availability block.'), findsOneWidget);
      expect(find.byType(BlockFormScreen), findsOneWidget);
    });

    testWidgets('a 422 past-date rejection is shown inline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BlockFormScreen(hotelId: 'h1', hallId: 'hall-1', initialDate: DateTime(2026, 9, 10)),
          (r) async =>
              errorResponse('BUSINESS_RULE_VIOLATION', 'A manual availability block must start in the future.', 422),
        ),
      );

      await tester.tap(_submitButton('Create Block'));
      await tester.pumpAndSettle();

      expect(find.text('A manual availability block must start in the future.'), findsOneWidget);
    });
  });

  group('Edit', () {
    testWidgets('pre-fills date, times, and reason from the existing block', (tester) async {
      final existing = AvailabilityBlock.fromJson(_blockJson());
      await tester.pumpWidget(
        _wrap(
          BlockFormScreen(
            hotelId: 'h1',
            hallId: 'hall-1',
            initialDate: DateTime(2026, 9, 10),
            existingBlock: existing,
          ),
          (r) async => successResponse(_blockJson()),
        ),
      );

      expect(find.text('2026-09-10'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget); // 07:00 UTC = 10:00 EAT
      expect(find.text('14:00'), findsOneWidget); // 11:00 UTC = 14:00 EAT
      expect(find.text('Maintenance'), findsOneWidget);
    });

    testWidgets('saving sends a PATCH to the block-scoped endpoint', (tester) async {
      final existing = AvailabilityBlock.fromJson(_blockJson());
      Map<String, dynamic>? sent;
      await tester.pumpWidget(
        _wrap(
          BlockFormScreen(
            hotelId: 'h1',
            hallId: 'hall-1',
            initialDate: DateTime(2026, 9, 10),
            existingBlock: existing,
          ),
          (r) async {
            sent = {'method': r.method, 'path': r.url.path};
            return successResponse(_blockJson());
          },
        ),
      );

      await tester.tap(_submitButton('Save changes'));
      await tester.pumpAndSettle();

      expect(sent!['method'], 'PATCH');
      expect(sent!['path'], '/api/v1/hotels/h1/halls/hall-1/availability/blocks/block-1');
    });
  });
}
