import 'package:customer_mobile/features/favorites/application/favorites_controller.dart';
import 'package:customer_mobile/features/favorites/data/favorites_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../test_support.dart';

FavoritesController _controllerWith(MockClient httpClient) {
  final client = ApiClient(httpClient: httpClient, baseUrl: 'http://test/api/v1');
  return FavoritesController(FavoritesRepository(client));
}

void main() {
  test('load populates saved Hotel IDs from the backend', () async {
    final controller = _controllerWith(
      MockClient((_) async => successResponse(['h1', 'h2'])),
    );

    await controller.load();

    expect(controller.isSaved('h1'), true);
    expect(controller.isSaved('h2'), true);
    expect(controller.isSaved('h3'), false);
  });

  test('a load failure leaves saved state empty rather than throwing', () async {
    final controller = _controllerWith(
      MockClient((_) async => errorResponse('INTERNAL_SERVER_ERROR', 'failed', 500)),
    );

    await controller.load();

    expect(controller.isSaved('h1'), false);
    expect(controller.isLoading, false);
  });

  test('toggle saves an unsaved Hotel: PUT request, optimistic flip to true', () async {
    var putCalled = false;
    final controller = _controllerWith(
      MockClient((request) async {
        if (request.method == 'PUT') {
          putCalled = true;
          expect(request.url.path, '/api/v1/favorites/hotels/h1');
        }
        return successResponse({'hotelId': 'h1', 'saved': true});
      }),
    );

    final future = controller.toggle('h1');
    expect(controller.isSaved('h1'), true, reason: 'optimistic flip happens synchronously');
    await future;

    expect(putCalled, true);
    expect(controller.isSaved('h1'), true);
  });

  test('toggle unsaves an already-saved Hotel: DELETE request, optimistic flip to false', () async {
    var deleteCalled = false;
    final controller = _controllerWith(
      MockClient((request) async {
        if (request.method == 'GET') return successResponse(['h1']);
        if (request.method == 'DELETE') {
          deleteCalled = true;
          expect(request.url.path, '/api/v1/favorites/hotels/h1');
        }
        return http.Response('', 204);
      }),
    );
    await controller.load();
    expect(controller.isSaved('h1'), true);

    await controller.toggle('h1');

    expect(deleteCalled, true);
    expect(controller.isSaved('h1'), false);
  });

  test('a failed save reverts the optimistic flip back to unsaved', () async {
    final controller = _controllerWith(
      MockClient((_) async => errorResponse('INTERNAL_SERVER_ERROR', 'failed', 500)),
    );

    await controller.toggle('h1');

    expect(controller.isSaved('h1'), false);
  });

  test('a failed unsave reverts the optimistic flip back to saved', () async {
    final controller = _controllerWith(
      MockClient((request) async {
        if (request.method == 'GET') return successResponse(['h1']);
        return errorResponse('INTERNAL_SERVER_ERROR', 'failed', 500);
      }),
    );
    await controller.load();
    expect(controller.isSaved('h1'), true);

    await controller.toggle('h1');

    expect(controller.isSaved('h1'), true);
  });
}
