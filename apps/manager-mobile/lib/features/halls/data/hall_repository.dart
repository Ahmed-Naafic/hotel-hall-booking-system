import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'hall_models.dart';

/// One function per own-Hotel-scoped Hall endpoint actually implemented
/// (WBS-05, `openapi.json`) — `POST`/`GET`/`PATCH /hotels/:hotelId/halls[/:id]`.
/// No Hall deletion, activation/deactivation, or pricing endpoint is called
/// here because none exists in the approved API.
class HallRepository {
  HallRepository(this._client);

  final ApiClient _client;

  /// `POST /api/v1/hotels/:hotelId/halls` — HL1/HL2, `BR-HALL-02`: no
  /// precondition on the owning Hotel's own status.
  Future<Hall> createHall({
    required String hotelId,
    Map<String, dynamic>? profileData,
  }) async {
    final data = await _client.post(
      '/hotels/$hotelId/halls',
      body: {'profileData': profileData},
    );
    return Hall.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /api/v1/hotels/:hotelId/halls` — the owning Manager sees every
  /// Hall regardless of visibility (offset pagination,
  /// `coding-standards.md` §6). `pagination` is a sibling of `data` in the
  /// envelope (`hall.controller.js#listHallsForHotel`), never nested inside
  /// it — `getPaginated` is what exposes it (plain `get()` would discard
  /// it).
  Future<HallPage> listHalls({
    required String hotelId,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _client.getPaginated(
      '/hotels/$hotelId/halls',
      query: {'page': '$page', 'limit': '$limit'},
    );
    final halls = (result.data as List<dynamic>)
        .map((h) => Hall.fromJson(h as Map<String, dynamic>))
        .toList();
    final pagination = result.pagination ?? const {};
    return HallPage(
      halls: halls,
      page: pagination['page'] as int? ?? page,
      limit: pagination['limit'] as int? ?? limit,
      total: pagination['total'] as int? ?? halls.length,
      hasNext: pagination['hasNext'] as bool? ?? false,
      hasPrevious: pagination['hasPrevious'] as bool? ?? false,
    );
  }

  /// `GET /api/v1/hotels/:hotelId/halls/:id` — HL2/HL3, own-Hotel scoped.
  Future<Hall> getHall({required String hotelId, required String id}) async {
    final data = await _client.get('/hotels/$hotelId/halls/$id');
    return Hall.fromJson(data as Map<String, dynamic>);
  }

  /// `PATCH /api/v1/hotels/:hotelId/halls/:id` — HL3, `BR-HALL-07`: applies
  /// immediately, no review step.
  Future<Hall> updateHall({
    required String hotelId,
    required String id,
    required Map<String, dynamic> profileData,
  }) async {
    final data = await _client.patch(
      '/hotels/$hotelId/halls/$id',
      body: profileData,
    );
    return Hall.fromJson(data as Map<String, dynamic>);
  }
}
