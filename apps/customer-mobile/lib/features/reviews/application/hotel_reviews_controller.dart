import 'package:flutter/foundation.dart';

import '../data/review.dart';
import '../data/review_repository.dart';

enum HotelReviewsState { loading, loaded, empty, error }

/// Hotel Detail's review list (Ratings & Reviews V1, approved business
/// decisions) — server-side cursor pagination, same convention as
/// AllHallsController; never loads a Hotel's whole review table at once.
class HotelReviewsController extends ChangeNotifier {
  HotelReviewsController(this.repository, this.hotelId);
  final ReviewRepository repository;
  final String hotelId;

  HotelReviewsState state = HotelReviewsState.loading;
  List<Review> reviews = [];
  String? errorMessage;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? _nextCursor;

  Future<void> load() async {
    state = HotelReviewsState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final page = await repository.getHotelReviews(hotelId);
      reviews = page.reviews;
      hasMore = page.hasNext;
      _nextCursor = page.nextCursor;
      state = reviews.isEmpty ? HotelReviewsState.empty : HotelReviewsState.loaded;
    } catch (_) {
      errorMessage = 'Could not load reviews. Please try again.';
      state = HotelReviewsState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore || state != HotelReviewsState.loaded) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await repository.getHotelReviews(hotelId, cursor: _nextCursor);
      reviews = [...reviews, ...page.reviews];
      hasMore = page.hasNext;
      _nextCursor = page.nextCursor;
    } catch (_) {
      // Keep what's already loaded; the customer can retry by scrolling again.
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }
}
