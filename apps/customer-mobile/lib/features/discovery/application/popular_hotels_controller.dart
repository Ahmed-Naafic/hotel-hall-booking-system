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
  String _search = '';

  // Ranking here is driven by qualifying (CONFIRMED/COMPLETED) Booking
  // counts (approved V1 business rules) — the one Discover ranking that a
  // Customer's own Booking action can actually change. This controller is
  // app-wide (registered once in main.dart, not per-screen) specifically
  // so a successful booking elsewhere in the app can mark it stale; the
  // next time the Customer actually looks at Popular Hotels, it silently
  // refetches instead of showing whatever was true before the booking.
  // Never refetches eagerly on its own — that would be an unprompted
  // extra API call for a screen the Customer isn't even looking at.
  bool isStale = false;

  void markStale() {
    isStale = true;
  }

  Future<void> load() async {
    state = PopularHotelsState.loading;
    errorMessage = null;
    isStale = false;
    notifyListeners();
    try {
      hotels = await repository.getPopularHotels(search: _search);
      state = hotels.isEmpty ? PopularHotelsState.empty : PopularHotelsState.loaded;
    } catch (_) {
      errorMessage = 'Could not load popular Hotels. Please try again.';
      state = PopularHotelsState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Narrows the popularity ranking by Hotel name/address — a full `load()`
  /// under the hood (never a separate lighter path) since Popular has no
  /// per-device state like Nearby's own cached coordinates to preserve.
  Future<void> search(String query) {
    _search = query;
    return load();
  }
}
