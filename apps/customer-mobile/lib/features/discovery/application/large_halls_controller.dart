import 'package:flutter/foundation.dart';

import '../data/discovery_repository.dart';
import '../data/large_hall.dart';

enum LargeHallsState { loading, loaded, empty, error }

/// Large Halls (approved V1 business rules) — no location permission and no
/// authentication involved; a plain load/loaded/empty/error controller,
/// the same shape as PopularHotelsController.
class LargeHallsController extends ChangeNotifier {
  LargeHallsController(this.repository);
  final DiscoveryRepository repository;

  LargeHallsState state = LargeHallsState.loading;
  List<LargeHall> halls = [];
  String? errorMessage;

  Future<void> load() async {
    state = LargeHallsState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      halls = await repository.getLargeHalls();
      state = halls.isEmpty ? LargeHallsState.empty : LargeHallsState.loaded;
    } catch (_) {
      errorMessage = 'Could not load large Halls. Please try again.';
      state = LargeHallsState.error;
    } finally {
      notifyListeners();
    }
  }
}
