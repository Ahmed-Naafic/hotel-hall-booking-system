import 'package:flutter/foundation.dart';

import '../data/discovery_repository.dart';
import '../data/large_hall.dart';
import '../../../core/request_generation.dart';

enum LargeHallsState { loading, loaded, empty, error }

/// Large Halls (approved V1 business rules) — no location permission and no
/// authentication involved; a plain load/loaded/empty/error controller,
/// the same shape as PopularHotelsController.
class LargeHallsController extends ChangeNotifier with RequestGeneration {
  LargeHallsController(this.repository, {String initialSearch = ''})
    : _search = initialSearch;
  final DiscoveryRepository repository;

  LargeHallsState state = LargeHallsState.loading;
  List<LargeHall> halls = [];
  String? errorMessage;
  String _search;


  Future<void> load() async {
    final request = beginRequest();
    state = LargeHallsState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getLargeHalls(search: _search);
      if (isSuperseded(request)) return;
      halls = result;
      state = halls.isEmpty ? LargeHallsState.empty : LargeHallsState.loaded;
    } catch (_) {
      if (isSuperseded(request)) return;
      errorMessage = 'Could not load large Halls. Please try again.';
      state = LargeHallsState.error;
    }
    notifyListeners();
  }

  /// Narrows the capacity ranking by Hall name — a full `load()` under the
  /// hood, the same shape `PopularHotelsController.search` uses.
  ///
  /// An unchanged query is already on screen (or already in flight, since
  /// this controller is created with the search box's current text), so it
  /// is not refetched. Retrying a *failed* load is the error state's own
  /// "Try again", not a repeat keystroke.
  Future<void> search(String query) {
    if (query == _search) return Future<void>.value();
    _search = query;
    return load();
  }
}
