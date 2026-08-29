import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../data/hotel_models.dart';
import '../data/hotel_repository.dart';

enum HotelContextStatus { unknown, none, loading, ready, error }

/// Resolves "which Hotel does the authenticated Hotel Manager manage" - the
/// one piece of context Hall Management's own endpoints require
/// (`/hotels/:hotelId/halls...`).
///
/// Hotel Management exposes `GET /hotels/me`, which returns the Hotel
/// Manager's latest Hotel plus the latest application decision state. The
/// local cache remains only as a convenience for existing app state between
/// refreshes.
class HotelContextController extends ChangeNotifier {
  HotelContextController({required this.repository, required this.storage});

  final HotelRepository repository;
  final TokenStorage storage;

  static const _hotelIdKey = 'hh_hotel_id';

  HotelContextStatus status = HotelContextStatus.unknown;
  Hotel? hotel;
  HotelApplication? latestApplication;
  String? errorMessage;

  Future<void> load() async {
    status = HotelContextStatus.loading;
    notifyListeners();

    try {
      final snapshot = await repository.getMyHotel();
      hotel = snapshot.hotel;
      latestApplication = snapshot.latestApplication;
      if (hotel == null) {
        await storage.delete(_hotelIdKey);
        status = HotelContextStatus.none;
      } else {
        await storage.write(_hotelIdKey, hotel!.id);
        status = HotelContextStatus.ready;
      }
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = HotelContextStatus.error;
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
      latestApplication = null;
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
    latestApplication = null;
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
      final snapshot = await repository.getMyHotel();
      hotel = snapshot.hotel;
      latestApplication = snapshot.latestApplication;
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
