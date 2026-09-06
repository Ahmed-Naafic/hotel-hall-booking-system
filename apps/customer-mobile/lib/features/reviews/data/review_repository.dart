import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'review.dart';

typedef ReviewPage = ({List<Review> reviews, bool hasNext, String? nextCursor});

/// Ratings & Reviews V1 (approved business decisions) — the backend is the
/// sole authority for what a Hotel's reviews are; this only parses the
/// already-ranked, already-paginated result.
class ReviewRepository {
  ReviewRepository(this.apiClient);
  final ApiClient apiClient;

  Future<ReviewPage> getHotelReviews(String hotelId, {String? cursor}) async {
    final response = await apiClient.getPaginated(
      '/hotels/$hotelId/reviews',
      query: {
        'limit': '20',
        if (cursor != null) 'cursor': cursor,
      },
    );
    final reviews = (response.data as List)
        .map((item) => Review.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
    final pagination = response.pagination ?? const {};
    return (
      reviews: reviews,
      hasNext: pagination['hasNext'] as bool? ?? false,
      nextCursor: pagination['nextCursor'] as String?,
    );
  }
}
