import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'discovery_models.dart';

class DiscoveryRepository {
  DiscoveryRepository(this.apiClient);
  final ApiClient apiClient;

  Future<List<HotelSummary>> getHotels() async {
    final response = await apiClient.getPaginated('/hotels/public');
    return (response.data as List)
        .map(
          (item) =>
              HotelSummary.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<HotelSummary> getHotel(String id) async {
    final data = await apiClient.get('/hotels/public/$id');
    return HotelSummary.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<List<HallSummary>> getHalls(String hotelId) async {
    final response = await apiClient.getPaginated(
      '/halls',
      query: {'hotelId': hotelId},
    );
    return (response.data as List)
        .map(
          (item) => HallSummary.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }
}
