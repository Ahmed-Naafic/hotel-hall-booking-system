import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'browsable_hall.dart';
import 'discovery_models.dart';
import 'large_hall.dart';
import 'nearby_hotel.dart';
import 'popular_hotel.dart';

typedef HallPage = ({List<BrowsableHall> halls, bool hasNext, String? nextCursor});
typedef HotelPage = ({List<HotelSummary> hotels, bool hasNext, String? nextCursor});

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

  /// Hotel Search (`BDR-020`) — the backend is authoritative: matching
  /// happens server-side against every Approved/Active Hotel, never by
  /// filtering a page already loaded on the device. Shares
  /// `GET /hotels/public`'s existing cursor pagination with the unsearched
  /// browse above — a searched result set pages exactly the same way.
  Future<HotelPage> searchHotels({required String search, String? cursor}) async {
    final response = await apiClient.getPaginated(
      '/hotels/public',
      query: {
        'limit': '20',
        'search': search,
        if (cursor != null) 'cursor': cursor,
      },
    );
    final hotels = (response.data as List)
        .map(
          (item) =>
              HotelSummary.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
    final pagination = response.pagination ?? const {};
    return (
      hotels: hotels,
      hasNext: pagination['hasNext'] as bool? ?? false,
      nextCursor: pagination['nextCursor'] as String?,
    );
  }

  Future<HotelSummary> getHotel(String id) async {
    final data = await apiClient.get('/hotels/public/$id');
    return HotelSummary.fromJson((data as Map).cast<String, dynamic>());
  }

  /// Nearby Hotels (approved V1 business rules) — the backend is
  /// authoritative for the geographic distance calculation and the fixed
  /// 5km filter; this only forwards the device's coordinates and parses
  /// the already-filtered, already-sorted result.
  Future<List<NearbyHotel>> getNearbyHotels({
    required double latitude,
    required double longitude,
  }) async {
    final data = await apiClient.get(
      '/hotels/public/nearby',
      query: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );
    return (data as List)
        .map((item) => NearbyHotel.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Popular Hotels (approved V1 business rules) — the backend is
  /// authoritative for the qualifying-booking count and ranking; this only
  /// parses the already-ranked result. No authentication, no location.
  Future<List<PopularHotel>> getPopularHotels() async {
    final data = await apiClient.get('/hotels/public/popular');
    return (data as List)
        .map((item) => PopularHotel.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Large Halls (approved V1 business rules) — the backend is
  /// authoritative for the capacity ranking; Customer Mobile never sorts
  /// this itself. No authentication, no location.
  Future<List<LargeHall>> getLargeHalls() async {
    final data = await apiClient.get('/halls/large-capacity');
    return (data as List)
        .map((item) => LargeHall.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  /// All Halls (approved V1 business rules) — the existing platform-wide
  /// browse endpoint already satisfies every rule (public, cursor-paginated,
  /// APPROVED_ACTIVE-only via the Visibility Component, no ranking): this
  /// is not a new endpoint, just called without a `hotelId` filter. Flutter
  /// only ever asks for one page at a time — it never loads the whole
  /// Hall table into memory.
  Future<HallPage> getAllHalls({String? cursor}) async {
    final response = await apiClient.getPaginated(
      '/halls',
      query: {
        'limit': '20',
        if (cursor != null) 'cursor': cursor,
      },
    );
    final halls = (response.data as List)
        .map((item) => BrowsableHall.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
    final pagination = response.pagination ?? const {};
    return (
      halls: halls,
      hasNext: pagination['hasNext'] as bool? ?? false,
      nextCursor: pagination['nextCursor'] as String?,
    );
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
