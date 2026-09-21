import 'package:flutter/foundation.dart';

import '../data/browsable_hall.dart';
import '../data/discovery_repository.dart';

enum AllHallsState { loading, loaded, empty, error }

/// Advanced Filters (Discover screen's own filter icon, All Halls only) —
/// each field independent and optional, applied server-side
/// (`hall.controller.js#browseHalls`). `minPriceCents`/`maxPriceCents` are
/// whole-dollar-derived cents, never a fractional-cent value a customer
/// couldn't have actually typed.
class AdvancedHallFilters {
  const AdvancedHallFilters({this.minCapacity, this.minPriceCents, this.maxPriceCents});

  final int? minCapacity;
  final int? minPriceCents;
  final int? maxPriceCents;

  bool get isEmpty => minCapacity == null && minPriceCents == null && maxPriceCents == null;

  static const none = AdvancedHallFilters();
}

/// All Halls (approved V1 business rules) — server-side cursor pagination;
/// this controller only ever holds the pages already fetched, never the
/// whole Hall table. No ranking, no location, no authentication.
class AllHallsController extends ChangeNotifier {
  AllHallsController(this.repository);
  final DiscoveryRepository repository;

  AllHallsState state = AllHallsState.loading;
  List<BrowsableHall> halls = [];
  String? errorMessage;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? _nextCursor;
  AdvancedHallFilters filters = AdvancedHallFilters.none;
  String _search = '';

  Future<void> load() async {
    state = AllHallsState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final page = await repository.getAllHalls(
        minCapacity: filters.minCapacity,
        minPriceCents: filters.minPriceCents,
        maxPriceCents: filters.maxPriceCents,
        search: _search,
      );
      halls = page.halls;
      hasMore = page.hasNext;
      _nextCursor = page.nextCursor;
      state = halls.isEmpty ? AllHallsState.empty : AllHallsState.loaded;
    } catch (_) {
      errorMessage = 'Could not load Halls. Please try again.';
      state = AllHallsState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Replaces the active filters and reloads from the first page — the same
  /// "start over" semantics changing the search text or a filter chip
  /// already has elsewhere on this screen.
  Future<void> applyFilters(AdvancedHallFilters next) {
    filters = next;
    return load();
  }

  /// Narrows the same "All Halls" list by Hall/Hotel name — a full `load()`
  /// under the hood, same as the Advanced Filters do; the search box and
  /// the filter sheet are two independent narrowings of one request.
  Future<void> search(String query) {
    _search = query;
    return load();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore || state != AllHallsState.loaded) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await repository.getAllHalls(
        cursor: _nextCursor,
        minCapacity: filters.minCapacity,
        minPriceCents: filters.minPriceCents,
        maxPriceCents: filters.maxPriceCents,
        search: _search,
      );
      halls = [...halls, ...page.halls];
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
