import 'dart:convert';

import 'package:customer_mobile/features/reviews/application/hotel_reviews_controller.dart';
import 'package:customer_mobile/features/reviews/data/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _paginatedResponse(
  List<Map<String, dynamic>> data, {
  required bool hasNext,
  String? nextCursor,
}) => http.Response(
  jsonEncode({
    'status': 'success',
    'message': 'ok',
    'data': data,
    'pagination': {'limit': 20, 'hasNext': hasNext, 'nextCursor': nextCursor},
  }),
  200,
);

Map<String, dynamic> _reviewJson(String id, {int rating = 5, String? text}) => {
  'id': id,
  'rating': rating,
  'text': text,
  'createdAt': '2026-01-01T00:00:00.000Z',
};

void main() {
  test('loads the first page', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => _paginatedResponse([_reviewJson('r1'), _reviewJson('r2')], hasNext: false),
      ),
      baseUrl: 'http://test/api/v1',
    );
    final controller = HotelReviewsController(ReviewRepository(client), 'hotel-1');

    await controller.load();

    expect(controller.state, HotelReviewsState.loaded);
    expect(controller.reviews.map((r) => r.id), ['r1', 'r2']);
    expect(controller.hasMore, false);
  });

  test('an empty first page is an empty state', () async {
    final client = ApiClient(
      httpClient: MockClient((_) async => _paginatedResponse([], hasNext: false)),
      baseUrl: 'http://test/api/v1',
    );
    final controller = HotelReviewsController(ReviewRepository(client), 'hotel-1');

    await controller.load();

    expect(controller.state, HotelReviewsState.empty);
  });

  test('loadMore appends the next page using the returned cursor', () async {
    final requestedCursors = <String?>[];
    final client = ApiClient(
      httpClient: MockClient((request) async {
        requestedCursors.add(request.url.queryParameters['cursor']);
        if (request.url.queryParameters['cursor'] == null) {
          return _paginatedResponse([_reviewJson('r1')], hasNext: true, nextCursor: 'r1');
        }
        return _paginatedResponse([_reviewJson('r2')], hasNext: false);
      }),
      baseUrl: 'http://test/api/v1',
    );
    final controller = HotelReviewsController(ReviewRepository(client), 'hotel-1');

    await controller.load();
    expect(controller.hasMore, true);

    await controller.loadMore();

    expect(controller.reviews.map((r) => r.id), ['r1', 'r2']);
    expect(controller.hasMore, false);
    expect(requestedCursors, [null, 'r1']);
  });

  test('loadMore does nothing once hasMore is false', () async {
    var requestCount = 0;
    final client = ApiClient(
      httpClient: MockClient((_) async {
        requestCount++;
        return _paginatedResponse([_reviewJson('r1')], hasNext: false);
      }),
      baseUrl: 'http://test/api/v1',
    );
    final controller = HotelReviewsController(ReviewRepository(client), 'hotel-1');

    await controller.load();
    expect(requestCount, 1);

    await controller.loadMore();
    expect(requestCount, 1, reason: 'loadMore must not fetch when hasMore is false');
  });

  test('a backend/network failure is a retryable error', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'status': 'error',
            'error': 'INTERNAL_SERVER_ERROR',
            'message': 'failed',
            'timestamp': '',
            'requestId': 'r',
          }),
          500,
        ),
      ),
      baseUrl: 'http://test/api/v1',
    );
    final controller = HotelReviewsController(ReviewRepository(client), 'hotel-1');

    await controller.load();

    expect(controller.state, HotelReviewsState.error);
    expect(controller.errorMessage, isNotNull);
  });

  test('parses rating, optional text, and createdAt', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => _paginatedResponse(
          [_reviewJson('r1', rating: 4, text: 'Nice stay')],
          hasNext: false,
        ),
      ),
      baseUrl: 'http://test/api/v1',
    );
    final controller = HotelReviewsController(ReviewRepository(client), 'hotel-1');

    await controller.load();

    expect(controller.reviews.single.rating, 4);
    expect(controller.reviews.single.text, 'Nice stay');
  });
}
