import 'package:flutter/foundation.dart';

import '../../discovery/data/discovery_models.dart';
import '../../discovery/data/discovery_repository.dart';
import 'favorites_controller.dart';

/// Saved Hotels (Customer Mobile) — resolves the Customer's saved Hotel IDs
/// (already held by [FavoritesController]) into full [HotelSummary] data via
/// the existing `GET /hotels/public/:id`, one call per saved Hotel. No new
/// backend endpoint: a Customer's saved list is small and personal, unlike
/// platform-wide browse, so per-ID fetch is the smallest correct approach.
/// A saved Hotel that no longer exists (e.g. deleted) is silently dropped
/// from the list rather than surfacing an error for the whole screen.
class SavedHotelsController extends ChangeNotifier {
  SavedHotelsController({
    required this.repository,
    required this.favorites,
  }) {
    favorites.addListener(_onFavoritesChanged);
  }

  final DiscoveryRepository repository;
  final FavoritesController favorites;

  List<HotelSummary> hotels = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final ids = favorites.savedHotelIds;
      final results = await Future.wait(
        ids.map((id) => repository.getHotel(id).then<HotelSummary?>((h) => h).catchError((_) => null)),
      );
      hotels = results.whereType<HotelSummary>().toList();
    } catch (_) {
      errorMessage = 'Could not load your saved Hotels. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Keeps the visible list in sync with unsaving — whether done from this
  /// screen's own tile or from Hotel Detail while navigated away from here.
  /// Never adds a Hotel on its own — a newly-saved Hotel appears next time
  /// this screen loads.
  void _onFavoritesChanged() {
    final before = hotels.length;
    hotels = hotels.where((h) => favorites.isSaved(h.id)).toList();
    if (hotels.length != before) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    favorites.removeListener(_onFavoritesChanged);
    super.dispose();
  }
}
