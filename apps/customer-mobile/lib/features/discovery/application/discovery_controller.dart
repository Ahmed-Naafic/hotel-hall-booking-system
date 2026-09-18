import 'package:flutter/foundation.dart';

import '../data/discovery_models.dart';
import '../data/discovery_repository.dart';

class DiscoveryController extends ChangeNotifier {
  DiscoveryController(this.repository);
  final DiscoveryRepository repository;
  List<HotelSummary> hotels = [];
  bool isLoading = false;
  String? errorMessage;

  // Hotel Search (`BDR-020`) — shares `hotels`/`isLoading`/`errorMessage`
  // above with the unsearched browse fetch: the "All Hotels" tab renders
  // exactly one of the two at a time, never both, and `isSearchActive` says
  // which. Server-side, cursor-paginated — this never holds more than the
  // pages actually fetched, unlike loading every Hotel to filter locally.
  bool isSearchActive = false;
  bool hasMoreSearchResults = false;
  bool isLoadingMoreSearchResults = false;
  String _searchQuery = '';
  String? _searchCursor;

  Future<void> loadHotels() async {
    isLoading = true;
    errorMessage = null;
    isSearchActive = false;
    notifyListeners();
    try {
      hotels = await repository.getHotels();
    } catch (_) {
      errorMessage = 'Could not load Hotels. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Runs a Hotel search, or clears back to the plain unsearched browse when
  /// `query` is blank. Replaces `hotels` with the first page of matches.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await loadHotels();
      return;
    }
    _searchQuery = trimmed;
    isSearchActive = true;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final page = await repository.searchHotels(search: trimmed);
      hotels = page.hotels;
      hasMoreSearchResults = page.hasNext;
      _searchCursor = page.nextCursor;
    } catch (_) {
      errorMessage = 'Could not search Hotels. Please try again.';
      hotels = [];
      hasMoreSearchResults = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSearchResults() async {
    if (!isSearchActive || isLoadingMoreSearchResults || !hasMoreSearchResults) {
      return;
    }
    isLoadingMoreSearchResults = true;
    notifyListeners();
    try {
      final page = await repository.searchHotels(
        search: _searchQuery,
        cursor: _searchCursor,
      );
      hotels = [...hotels, ...page.hotels];
      hasMoreSearchResults = page.hasNext;
      _searchCursor = page.nextCursor;
    } catch (_) {
      // Keep what's already loaded; the customer can retry by scrolling again.
    } finally {
      isLoadingMoreSearchResults = false;
      notifyListeners();
    }
  }
}
