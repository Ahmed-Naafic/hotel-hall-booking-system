import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../../../core/sync/local_replica.dart';
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
///
/// **Offline.** Every tab calls [load] again when it is revisited, so it must
/// never turn a Hotel it already knows into an error just because the server
/// is unreachable: the Halls tab is built only while [status] is `ready`, and
/// an offline refresh used to replace the (locally readable) Hall list with
/// "Could not reach the server". On a [NetworkException] a known Hotel is kept
/// and [isOffline] is set; with none known, the Hotel is taken from the local
/// [replica] if it holds one for this Manager. A server *response* — any
/// [ApiException] — still wins: this only covers not being able to ask.
class HotelContextController extends ChangeNotifier {
  HotelContextController({required this.repository, required this.storage, this.replica});

  final HotelRepository repository;
  final TokenStorage storage;

  /// Optional — absent in tests and wherever no replica exists, in which case
  /// being offline is an error, as it always was.
  final LocalReplica? replica;

  /// The Hotel shown was resolved without the server — kept from an earlier
  /// load or read from the replica — because the server could not be reached.
  /// Its application state and review summary may be missing or out of date.
  bool isOffline = false;

  static const _hotelIdKey = 'hh_hotel_id';

  HotelContextStatus status = HotelContextStatus.unknown;
  Hotel? hotel;
  HotelApplication? latestApplication;
  ReviewSummary? reviewSummary;
  String? errorMessage;

  Future<void> load() async {
    // Revalidating a context that is already resolved keeps showing it: no
    // loading flash, and no teardown of the tabs built on it.
    final known = status == HotelContextStatus.ready || status == HotelContextStatus.none;
    if (!known) {
      status = HotelContextStatus.loading;
      notifyListeners();
    }

    try {
      final snapshot = await repository.getMyHotel();
      hotel = snapshot.hotel;
      latestApplication = snapshot.latestApplication;
      reviewSummary = snapshot.reviewSummary;
      if (hotel == null) {
        await storage.delete(_hotelIdKey);
        status = HotelContextStatus.none;
      } else {
        await storage.write(_hotelIdKey, hotel!.id);
        status = HotelContextStatus.ready;
      }
      isOffline = false;
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = HotelContextStatus.error;
      isOffline = false;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      if (known) {
        isOffline = true;
        replica?.noteUnreachable(e);
      } else if (await _loadFromReplica()) {
        isOffline = true;
        replica?.noteUnreachable(e);
        status = HotelContextStatus.ready;
      } else {
        status = HotelContextStatus.error;
      }
    }
    notifyListeners();
  }

  /// The Manager's Hotel from the replica — the most recently created, which
  /// is the one `GET /hotels/me` returns — with its latest application (the
  /// most recently submitted, as `/hotels/me` picks it). The review summary is
  /// a server aggregate that is not replicated, and stays unknown offline.
  Future<bool> _loadFromReplica() async {
    final rows = await replica?.readAll('hotel');
    if (rows == null || rows.isEmpty) return false;
    rows.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    hotel = Hotel.fromJson(rows.first);
    latestApplication = await _latestApplicationFromReplica(hotel!.id);
    reviewSummary = null;
    return true;
  }

  Future<HotelApplication?> _latestApplicationFromReplica(String hotelId) async {
    final rows = (await replica?.readAll('hotelApplication'))
        ?.where((row) => row['hotelId'] == hotelId)
        .toList();
    if (rows == null || rows.isEmpty) return null;
    rows.sort((a, b) => (b['submittedAt'] as String).compareTo(a['submittedAt'] as String));
    return HotelApplication.fromJson(rows.first);
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
    reviewSummary = null;
    isOffline = false;
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
      reviewSummary = snapshot.reviewSummary;
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
