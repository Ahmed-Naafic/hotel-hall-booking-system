import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:customer_mobile/features/availability/application/availability_controller.dart';
import 'package:customer_mobile/features/availability/data/availability_repository.dart';

import '../../test_support.dart';

AvailabilityController _controller(Future<http.Response> Function(http.Request) handler) {
  final client = ApiClient(httpClient: MockClient(handler), baseUrl: 'http://test/api/v1');
  return AvailabilityController(
    repository: AvailabilityRepository(client),
    hallId: 'hall-1',
    initialDate: DateTime(2026, 9, 10),
  );
}

void main() {
  test('load() populates busyPeriods and reaches status ready', () async {
    final controller = _controller(
      (r) async => successResponse({
        'busyPeriods': [
          {'start': '2026-09-10T07:00:00.000Z', 'end': '2026-09-10T11:00:00.000Z'},
        ],
      }),
    );
    await controller.load();

    expect(controller.status, AvailabilityStatus.ready);
    expect(controller.busyPeriods, hasLength(1));
  });

  test('load() with no busy periods still reaches status ready with an empty list', () async {
    final controller = _controller((r) async => successResponse({'busyPeriods': []}));
    await controller.load();

    expect(controller.status, AvailabilityStatus.ready);
    expect(controller.busyPeriods, isEmpty);
  });

  test('load() surfaces an API error (e.g. a Hidden Hall) as status error', () async {
    final controller = _controller((r) async => errorResponse('NOT_FOUND', 'Hall not found.', 404));
    await controller.load();

    expect(controller.status, AvailabilityStatus.error);
    expect(controller.errorMessage, 'Hall not found.');
  });

  test('submitCheck() returns true for an available period', () async {
    final controller = _controller((r) async => successResponse({'available': true}));
    final result = await controller.submitCheck(startTime: '10:00', endTime: '14:00');

    expect(result, true);
    expect(controller.isChecking, false);
  });

  test('submitCheck() returns false when the backend rejects the period (rule 12)', () async {
    final controller = _controller((r) async => successResponse({'available': false}));
    final result = await controller.submitCheck(startTime: '10:00', endTime: '14:00');

    expect(result, false);
  });

  test('submitCheck() returns null and surfaces the server message on failure', () async {
    final controller = _controller((r) async => errorResponse('AUTHENTICATION_ERROR', 'Please log in again.', 401));
    final result = await controller.submitCheck(startTime: '10:00', endTime: '14:00');

    expect(result, null);
    expect(controller.checkErrorMessage, 'Please log in again.');
  });
}
