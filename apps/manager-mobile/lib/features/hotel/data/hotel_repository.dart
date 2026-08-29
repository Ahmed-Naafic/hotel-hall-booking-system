import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'hotel_models.dart';

/// Wraps the two Hotel Management endpoints this app needs — `POST
/// /hotels` (own-Hotel creation) and `GET /hotels/:id` (own-Hotel
/// retrieval). No other Hotel Management endpoint is called from Manager
/// Mobile's Hall screens (`api-standards.md`, Hotel Management Technical
/// Design §11) — this module never calls `GET /hotels` (Platform-
/// Administrator-only) or any application/review endpoint.
class HotelRepository {
  HotelRepository(this._client);

  final ApiClient _client;

  Future<MyHotelSnapshot> getMyHotel() async {
    final data = await _client.get('/hotels/me');
    return MyHotelSnapshot.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /api/v1/hotels` — creates a Hotel owned by the authenticated
  /// caller (Hotel Management Technical Design §11). Hall Management
  /// "begins from the premise that a Hotel entity already exists" (Hall
  /// Management Business Specification §3) — this call is Hotel
  /// Management's own, unmodified, already-implemented endpoint, used here
  /// only because no approved backend query lets a Hotel Manager discover
  /// an existing Hotel's id without already knowing it (see
  /// `HotelContextController`'s own doc comment for the full explanation).
  Future<Hotel> createHotel() async {
    final data = await _client.post('/hotels', body: const {});
    return Hotel.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /api/v1/hotels/:id` — own-Hotel only; `404` if not found or not
  /// owned by the caller (never leaked, api-standards.md §9).
  Future<Hotel> getHotel(String hotelId) async {
    final data = await _client.get('/hotels/$hotelId');
    return Hotel.fromJson(data as Map<String, dynamic>);
  }

  /// `PATCH /api/v1/hotels/:id` — completes a `REGISTERED` Hotel's initial
  /// profile (HM2, `BR-HOTEL-02`). The request body is the profile fields
  /// themselves, not wrapped in a `profileData` key (`hotel.controller.js`'s
  /// `updateHotel` passes `req.body` straight through to
  /// `profileService.completeProfile`) — unlike `POST /hotels`, which does
  /// wrap it. The backend requires at least one field and rejects an empty
  /// object with `422`. This method is only ever called while the Hotel is
  /// `REGISTERED`; the same endpoint behaves differently for `REJECTED` or
  /// `APPROVED_ACTIVE` Hotels (Technical Design §8), which this app does not
  /// call this method for.
  Future<Hotel> completeProfile(
    String hotelId,
    Map<String, dynamic> profileData,
  ) async {
    final data = await _client.patch('/hotels/$hotelId', body: profileData);
    return Hotel.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /api/v1/hotels/:id/applications` — submits the Hotel's
  /// application for Platform Administrator review (HM3, `BR-HOTEL-03`).
  /// Only valid from `PROFILE_COMPLETE` (`422` otherwise) or `REJECTED`
  /// (resubmission, `BR-HOTEL-07` — not exercised by this app yet); `409` if
  /// an application is already under review. The response body is the
  /// created Hotel Application, not the Hotel itself, so the caller
  /// re-fetches the Hotel afterward to observe its new `UNDER_REVIEW` status
  /// straight from the backend rather than assuming it locally.
  Future<void> submitApplication(String hotelId) async {
    await _client.post('/hotels/$hotelId/applications');
  }

  /// `POST /api/v1/hotels/:hotelId/media/logo` — uploads or replaces the
  /// Hotel Logo (`BDR-015`, `ADR-0006`, Technical Design §8a). At most one
  /// Logo per Hotel; the backend handles replacement, this app never
  /// deletes the previous one itself.
  Future<HotelMedia> uploadLogo(
    String hotelId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await _client.postMultipart(
      '/hotels/$hotelId/media/logo',
      bytes: bytes,
      filename: filename,
    );
    return HotelMedia.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /api/v1/hotels/:hotelId/media/photos` — adds a Hotel Photo. No
  /// replacement semantics — a Hotel may have any number of Photos.
  Future<HotelMedia> uploadPhoto(
    String hotelId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await _client.postMultipart(
      '/hotels/$hotelId/media/photos',
      bytes: bytes,
      filename: filename,
    );
    return HotelMedia.fromJson(data as Map<String, dynamic>);
  }

  /// `DELETE /api/v1/hotels/:hotelId/media/:mediaId` — deletes one Hotel
  /// Media record (Logo or Photo); `404` if it doesn't exist or belongs to
  /// a different Hotel Manager's own Hotel.
  Future<void> deleteMedia(String hotelId, String mediaId) async {
    await _client.delete('/hotels/$hotelId/media/$mediaId');
  }

  /// `GET /api/v1/hotels/:hotelId/media` — the Hotel's current Logo (or
  /// `null`) and full Photos list.
  Future<HotelMediaCollection> getMedia(String hotelId) async {
    final data = await _client.get('/hotels/$hotelId/media');
    return HotelMediaCollection.fromJson(data as Map<String, dynamic>);
  }
}
