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

  /// Which request the currently-displayed `hotels` belongs to. Both entry
  /// points here write the same fields, so clearing the box while a search
  /// is still in flight (or retyping past a slow response) would otherwise
  /// let the older response win. See `LargeHallsController._requestId`.
  int _requestId = 0;

  Future<void> loadHotels() async {
    final requestId = ++_requestId;
    isLoading = true;
    errorMessage = null;
    isSearchActive = false;
    isLoadingMoreSearchResults = false;
    notifyListeners();
    try {
      final result = await repository.getHotels();
      if (requestId != _requestId) return;
      hotels = result;
      hasMoreSearchResults = false;
      _searchCursor = null;
    } catch (_) {
      if (requestId != _requestId) return;
      errorMessage = 'Could not load Hotels. Please try again.';
    }
    isLoading = false;
    notifyListeners();
  }

  /// Runs a Hotel search, or clears back to the plain unsearched browse when
  /// `query` is blank. Replaces `hotels` with the first page of matches.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await loadHotels();
      return;
    }
    final requestId = ++_requestId;
    _searchQuery = trimmed;
    isSearchActive = true;
    isLoading = true;
    errorMessage = null;
    isLoadingMoreSearchResults = false;
    notifyListeners();
    try {
      final page = await repository.searchHotels(search: trimmed);
      if (requestId != _requestId) return;
      hotels = page.hotels;
      hasMoreSearchResults = page.hasNext;
      _searchCursor = page.nextCursor;
    } catch (_) {
      if (requestId != _requestId) return;
      errorMessage = 'Could not search Hotels. Please try again.';
      hotels = [];
      hasMoreSearchResults = false;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreSearchResults() async {
    if (!isSearchActive || isLoadingMoreSearchResults || !hasMoreSearchResults) {
      return;
    }
    // Appends to the generation already on screen — never takes a new one,
    // so a page that arrives after the query changed is dropped.
    final requestId = _requestId;
    isLoadingMoreSearchResults = true;
    notifyListeners();
    try {
      final page = await repository.searchHotels(
        search: _searchQuery,
        cursor: _searchCursor,
      );
      if (requestId != _requestId) return;
      hotels = [...hotels, ...page.hotels];
      hasMoreSearchResults = page.hasNext;
      _searchCursor = page.nextCursor;
    } catch (_) {
      // Keep what's already loaded; the customer can retry by scrolling again.
    } finally {
      if (requestId == _requestId) {
        isLoadingMoreSearchResults = false;
        notifyListeners();
      }
    }
  }
}
