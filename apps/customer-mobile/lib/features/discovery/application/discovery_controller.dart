import 'package:flutter/foundation.dart';

import '../data/discovery_models.dart';
import '../data/discovery_repository.dart';
import '../../../core/request_generation.dart';

class DiscoveryController extends ChangeNotifier with RequestGeneration {
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
    final request = beginRequest();
    isLoading = true;
    errorMessage = null;
    isSearchActive = false;
    isLoadingMoreSearchResults = false;
    notifyListeners();
    try {
      final result = await repository.getHotels();
      if (isSuperseded(request)) return;
      hotels = result;
      hasMoreSearchResults = false;
      _searchCursor = null;
    } catch (_) {
      if (isSuperseded(request)) return;
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
    final request = beginRequest();
    _searchQuery = trimmed;
    isSearchActive = true;
    isLoading = true;
    errorMessage = null;
    isLoadingMoreSearchResults = false;
    notifyListeners();
    try {
      final page = await repository.searchHotels(search: trimmed);
      if (isSuperseded(request)) return;
      hotels = page.hotels;
      hasMoreSearchResults = page.hasNext;
      _searchCursor = page.nextCursor;
    } catch (_) {
      if (isSuperseded(request)) return;
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
    final request = currentRequest();
    isLoadingMoreSearchResults = true;
    notifyListeners();
    try {
      final page = await repository.searchHotels(
        search: _searchQuery,
        cursor: _searchCursor,
      );
      if (isSuperseded(request)) return;
      hotels = [...hotels, ...page.hotels];
      hasMoreSearchResults = page.hasNext;
      _searchCursor = page.nextCursor;
    } catch (_) {
      // Keep what's already loaded; the customer can retry by scrolling again.
    } finally {
      if (!isSuperseded(request)) {
        isLoadingMoreSearchResults = false;
        notifyListeners();
      }
    }
  }
}
