import 'package:flutter/foundation.dart';

import '../data/browsable_hall.dart';
import '../data/discovery_repository.dart';

enum AllHallsState { loading, loaded, empty, error }

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

  Future<void> load() async {
    state = AllHallsState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final page = await repository.getAllHalls();
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

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore || state != AllHallsState.loaded) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await repository.getAllHalls(cursor: _nextCursor);
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
