import 'package:flutter/foundation.dart';

import '../data/favorites_repository.dart';

/// App-wide saved-Hotel state (Customer Mobile "save a Hotel" — icons-only
/// V1: no dedicated Saved Hotels screen yet). Registered once in `main.dart`
/// so the Discover screen's featured-hotel bookmark and Hotel Detail's
/// bookmark read/write the same state and stay in sync without either one
/// knowing about the other.
class FavoritesController extends ChangeNotifier {
  FavoritesController(this.repository);
  final FavoritesRepository repository;

  Set<String> _savedHotelIds = {};
  bool isLoading = false;

  bool isSaved(String hotelId) => _savedHotelIds.contains(hotelId);

  /// The Customer's currently-saved Hotel IDs, in no particular order —
  /// Saved Hotels reads this directly rather than re-fetching the same
  /// list this controller already holds.
  List<String> get savedHotelIds => List.unmodifiable(_savedHotelIds);

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      _savedHotelIds = (await repository.getSavedHotelIds()).toSet();
    } catch (_) {
      // Best-effort: an authenticated Customer who fails to load their
      // saved list simply sees every bookmark as unsaved until the next
      // successful load — never a blocking error on a background screen.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Optimistic toggle: flips immediately so the icon responds without a
  /// network round-trip, then reverts if the request fails.
  Future<void> toggle(String hotelId) async {
    final wasSaved = isSaved(hotelId);
    wasSaved ? _savedHotelIds.remove(hotelId) : _savedHotelIds.add(hotelId);
    notifyListeners();
    try {
      if (wasSaved) {
        await repository.unsaveHotel(hotelId);
      } else {
        await repository.saveHotel(hotelId);
      }
    } catch (_) {
      wasSaved ? _savedHotelIds.add(hotelId) : _savedHotelIds.remove(hotelId);
      notifyListeners();
    }
  }
}
