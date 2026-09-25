import 'package:flutter/foundation.dart';

import '../data/discovery_repository.dart';
import '../data/large_hall.dart';

enum LargeHallsState { loading, loaded, empty, error }

/// Large Halls (approved V1 business rules) — no location permission and no
/// authentication involved; a plain load/loaded/empty/error controller,
/// the same shape as PopularHotelsController.
class LargeHallsController extends ChangeNotifier {
  LargeHallsController(this.repository, {String initialSearch = ''})
    : _search = initialSearch;
  final DiscoveryRepository repository;

  LargeHallsState state = LargeHallsState.loading;
  List<LargeHall> halls = [];
  String? errorMessage;
  String _search;

  /// Which request the currently-displayed result set belongs to. Every
  /// [load] takes the next number and only writes its own result back if
  /// that number is still current — so a slow response for "guu" can never
  /// land on top of a newer "guuleed" one, whatever order the network
  /// happens to return them in. Without this the last *response* wins
  /// rather than the last *query*, which is how a search silently showed
  /// unfiltered results.
  int _requestId = 0;

  Future<void> load() async {
    final requestId = ++_requestId;
    state = LargeHallsState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getLargeHalls(search: _search);
      if (requestId != _requestId) return;
      halls = result;
      state = halls.isEmpty ? LargeHallsState.empty : LargeHallsState.loaded;
    } catch (_) {
      if (requestId != _requestId) return;
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
