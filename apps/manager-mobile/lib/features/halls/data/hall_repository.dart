import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'hall_models.dart';

/// One function per own-Hotel-scoped Hall endpoint actually implemented
/// (WBS-05, `openapi.json`) — `POST`/`GET`/`PATCH /hotels/:hotelId/halls[/:id]`.
/// No Hall deletion endpoint is called here because none exists in the
/// approved API; activation/deactivation is a plain `PATCH` (`setActive`
/// below) — the same endpoint `updateHall` already uses, not a separate
/// resource.
class HallRepository {
  HallRepository(this._client);

  final ApiClient _client;

  /// `POST /api/v1/hotels/:hotelId/halls` — HL1/HL2, `BR-HALL-02`: no
  /// precondition on the owning Hotel's own status.
  Future<Hall> createHall({
    required String hotelId,
    Map<String, dynamic>? profileData,
    required Map<String, dynamic> commercialData,
  }) async {
    final data = await _client.post(
      '/hotels/$hotelId/halls',
      body: {'profileData': profileData, ...commercialData},
    );
    return Hall.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /api/v1/hotels/:hotelId/halls` — the owning Manager sees every
  /// Hall regardless of visibility (offset pagination,
  /// `coding-standards.md` §6). `pagination` is a sibling of `data` in the
  /// envelope (`hall.controller.js#listHallsForHotel`), never nested inside
  /// it — `getPaginated` is what exposes it (plain `get()` would discard
  /// it).
  /// `search` matches Hall name (case-insensitive substring); `status`
  /// ('active'/'inactive') narrows the owning Manager's own "All" view —
  /// both optional, both passed straight through as query params.
  Future<HallPage> listHalls({
    required String hotelId,
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final result = await _client.getPaginated(
      '/hotels/$hotelId/halls',
      query: {
        'page': '$page',
        'limit': '$limit',
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
      },
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
    Map<String, dynamic> commercialData = const {},
  }) async {
    final data = await _client.patch(
      '/hotels/$hotelId/halls/$id',
      body: {...profileData, ...commercialData},
    );
    return Hall.fromJson(data as Map<String, dynamic>);
  }

  /// `PATCH /api/v1/hotels/:hotelId/halls/:id` with only `isActive` — the
  /// Manager's own on/off switch (no separate activation endpoint exists;
  /// this is the same generic update endpoint `updateHall` uses).
  Future<Hall> setActive({
    required String hotelId,
    required String id,
    required bool isActive,
  }) async {
    final data = await _client.patch(
      '/hotels/$hotelId/halls/$id',
      body: {'isActive': isActive},
    );
    return Hall.fromJson(data as Map<String, dynamic>);
  }

  Future<List<HallMedia>> getMedia({
    required String hotelId,
    required String hallId,
  }) async {
    final data =
        await _client.get('/hotels/$hotelId/halls/$hallId/media')
            as Map<String, dynamic>;
    return (data['photos'] as List<dynamic>? ?? const [])
        .map(
          (item) => HallMedia.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<HallMedia> uploadPhoto({
    required String hotelId,
    required String hallId,
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await _client.postMultipart(
      '/hotels/$hotelId/halls/$hallId/media/photos',
      bytes: bytes,
      filename: filename,
    );
    return HallMedia.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteMedia({
    required String hotelId,
    required String hallId,
    required String mediaId,
  }) => _client.delete('/hotels/$hotelId/halls/$hallId/media/$mediaId');
}
