import 'package:hotel_hall_core/hotel_hall_core.dart';

/// Favorites (Customer Mobile "save a Hotel") — a personal bookmark, never a
/// business rule or eligibility check (backend/src/modules/favorites). The
/// backend is authoritative for persistence; this only forwards the
/// customer's own toggle action and parses the already-saved Hotel ID list.
class FavoritesRepository {
  FavoritesRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<String>> getSavedHotelIds() async {
    final data = await apiClient.get('/favorites/hotels');
    return (data as List).cast<String>();
  }

  Future<void> saveHotel(String hotelId) =>
      apiClient.put('/favorites/hotels/$hotelId');

  Future<void> unsaveHotel(String hotelId) =>
      apiClient.delete('/favorites/hotels/$hotelId');
}
