import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../data/hotel_models.dart';
import '../data/hotel_repository.dart';

enum HotelContextStatus { unknown, none, loading, ready, error }

/// Resolves "which Hotel does the authenticated Hotel Manager manage" — the
/// one piece of context Hall Management's own endpoints require
/// (`/hotels/:hotelId/halls...`) that nothing in the currently-approved
/// backend contract can answer on its own.
///
/// **Why this exists (read before changing):** Hotel Management's API
/// exposes `POST /hotels` (create, owned by the caller) and `GET
/// /hotels/:id` (retrieve, own-Hotel scoped) — but no "list/find my own
/// Hotel(s)" query. `GET /hotels` is Platform-Administrator-only (`403` for
/// a Hotel Manager). `PublicUser` (the authenticated identity) carries no
/// Hotel reference either. So a freshly-authenticated Hotel Manager's
/// `hotelId` cannot be discovered from the API alone — only remembered,
/// once known, from the moment their Hotel was created.
///
/// Hall Management's own Business Specification §3 states this module
/// "begins from the premise that a Hotel entity already exists" — Hotel
/// creation is explicitly Hotel Management's concern, not Hall
/// Management's, and Hotel Management has no approved frontend task list
/// (`FE-##`-equivalent) of its own yet. Rather than block Hall Management's
/// Manager Mobile screens entirely on that gap (as Manager Mobile itself
/// was blocked on Module 1's missing auth foundation), this controller
/// resolves it with the narrowest possible action: call Hotel Management's
/// own existing, unmodified, already-approved `POST /hotels` endpoint —
/// never a new backend endpoint, never a new business rule — and cache the
/// returned id locally so it never needs to ask again on this device.
///
/// **Known limitation, not hidden:** the cached id lives only in this
/// device's secure storage, scoped independently of the shared
/// `SessionStore` (a Hotel is Manager-Mobile-only context; `hotel_hall_core`
/// stays Hall/Hotel-agnostic). A Manager who reinstalls the app or signs in
/// on a second device has no way to reconnect to an *existing* Hotel
/// through this app — the same underlying gap (no "find my Hotel" query),
/// surfaced honestly rather than worked around with a second guess.
class HotelContextController extends ChangeNotifier {
  HotelContextController({required this.repository, required this.storage});

  final HotelRepository repository;
  final TokenStorage storage;

  static const _hotelIdKey = 'hh_hotel_id';

  HotelContextStatus status = HotelContextStatus.unknown;
  Hotel? hotel;
  String? errorMessage;

  Future<void> load() async {
    status = HotelContextStatus.loading;
    notifyListeners();

    final cachedId = await storage.read(_hotelIdKey);
    if (cachedId == null) {
      status = HotelContextStatus.none;
      notifyListeners();
      return;
    }

    try {
      hotel = await repository.getHotel(cachedId);
      status = HotelContextStatus.ready;
    } on ApiException catch (e) {
      if (e.isNotFound) {
        // The cached id no longer resolves to a Hotel this account owns —
        // never re-invent one silently; ask again explicitly.
        await storage.delete(_hotelIdKey);
        status = HotelContextStatus.none;
      } else {
        errorMessage = e.message;
        status = HotelContextStatus.error;
      }
    } on NetworkException catch (e) {
      errorMessage = e.message;
      status = HotelContextStatus.error;
    }
    notifyListeners();
  }

  /// Explicit, user-initiated only — never called automatically, so an
  /// existing Manager is never at risk of a second Hotel being created
  /// behind their back.
  Future<bool> createHotel() async {
    status = HotelContextStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      hotel = await repository.createHotel();
      await storage.write(_hotelIdKey, hotel!.id);
      status = HotelContextStatus.ready;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = HotelContextStatus.none;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      status = HotelContextStatus.none;
      notifyListeners();
      return false;
    }
  }

  Future<void> clearOnLogout() async {
    await storage.delete(_hotelIdKey);
    hotel = null;
    status = HotelContextStatus.unknown;
  }

  /// Pushes an already-authoritative Hotel (returned directly by a backend
  /// write, e.g. `PATCH /hotels/:id`) back into this shared context, so
  /// every screen watching this controller (`MyHotelScreen`) reflects the
  /// new status immediately. Used by `HotelProfileFormController` — never
  /// called with a locally-guessed status.
  void setHotel(Hotel updated) {
    hotel = updated;
    notifyListeners();
  }

  bool isSubmittingApplication = false;

  /// Submits the current Hotel's application for Platform Administrator
  /// review (HM3, `BR-HOTEL-03`). The endpoint's response is the created
  /// Application, not the Hotel, so this re-fetches the Hotel afterward —
  /// `hotel.status` becomes `UNDER_REVIEW` because the backend says so, not
  /// because this controller assumes the transition (no local state
  /// machine).
  Future<bool> submitApplication() async {
    final current = hotel;
    if (current == null) return false;

    isSubmittingApplication = true;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.submitApplication(current.id);
      hotel = await repository.getHotel(current.id);
      isSubmittingApplication = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isSubmittingApplication = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      isSubmittingApplication = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
