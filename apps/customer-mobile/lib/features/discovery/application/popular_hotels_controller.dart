import 'package:flutter/foundation.dart';

import '../data/discovery_repository.dart';
import '../data/popular_hotel.dart';

enum PopularHotelsState { loading, loaded, empty, error }

/// Popular Hotels (approved V1 business rules) — no location permission and
/// no authentication involved at all, unlike Nearby Hotels; this is
/// deliberately a plain load/loaded/empty/error controller.
class PopularHotelsController extends ChangeNotifier {
  PopularHotelsController(this.repository);
  final DiscoveryRepository repository;

  PopularHotelsState state = PopularHotelsState.loading;
  List<PopularHotel> hotels = [];
  String? errorMessage;

  Future<void> load() async {
    state = PopularHotelsState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      hotels = await repository.getPopularHotels();
      state = hotels.isEmpty ? PopularHotelsState.empty : PopularHotelsState.loaded;
    } catch (_) {
      errorMessage = 'Could not load popular Hotels. Please try again.';
      state = PopularHotelsState.error;
    } finally {
      notifyListeners();
    }
  }
}
