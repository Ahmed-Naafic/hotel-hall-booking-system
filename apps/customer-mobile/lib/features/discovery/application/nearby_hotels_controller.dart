import 'package:flutter/foundation.dart';

import '../../../core/location_service.dart';
import '../data/discovery_repository.dart';
import '../data/nearby_hotel.dart';

/// The state Nearby Hotels can be in — kept distinct rather than a single
/// `errorMessage` string so the screen can show a permission-specific
/// message/action (approved business rule: denial must not look like a
/// generic failure, and must never affect normal Hotel/Hall browsing, which
/// this controller is never used for).
enum NearbyHotelsState {
  locating,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  loading,
  loaded,
  empty,
  error,
}

class NearbyHotelsController extends ChangeNotifier {
  NearbyHotelsController({
    required this.repository,
    required this.locationService,
    String initialSearch = '',
  }) : _search = initialSearch;

  final DiscoveryRepository repository;
  final LocationService locationService;

  NearbyHotelsState state = NearbyHotelsState.locating;
  List<NearbyHotel> hotels = [];
  String? errorMessage;
  String _search;
  // Cached from the last successful locate — re-searching the already-known
  // position never re-triggers a GPS fix, the same way a filter chip
  // elsewhere on this screen never re-fetches location either.
  double? _latitude;
  double? _longitude;

  /// Which request the currently-displayed `hotels` belongs to — see
  /// `LargeHallsController._requestId`. Taken by [load] and [_fetch] alike,
  /// so a locate-then-fetch sequence started earlier can never overwrite a
  /// newer search's results, and a stale location outcome can never push
  /// the screen back into a permission state the customer has moved past.
  int _requestId = 0;

  /// The query this controller will apply, exposed for the Discover screen
  /// to reason about — it is applied the moment a position is known, even
  /// if it was typed before the first locate resolved.
  String get pendingSearch => _search;

  /// True once a position is known, i.e. once searching this tab can
  /// actually run. Before that a query is remembered, not dropped.
  bool get hasLocation => _latitude != null && _longitude != null;

  Future<void> load() async {
    final requestId = ++_requestId;
    state = NearbyHotelsState.locating;
    errorMessage = null;
    notifyListeners();

    final location = await locationService.getCurrentLocation();
    if (requestId != _requestId) return;

    switch (location.outcome) {
      case LocationOutcome.permissionDenied:
        _failLocate(NearbyHotelsState.permissionDenied);
        return;
      case LocationOutcome.permissionDeniedForever:
        _failLocate(NearbyHotelsState.permissionDeniedForever);
        return;
      case LocationOutcome.serviceDisabled:
        _failLocate(NearbyHotelsState.serviceDisabled);
        return;
      case LocationOutcome.error:
        _failLocate(
          NearbyHotelsState.error,
          message: 'Could not determine your location. Please try again.',
        );
        return;
      case LocationOutcome.granted:
        break;
    }

    _latitude = location.latitude;
    _longitude = location.longitude;
    await _fetch(requestId: requestId);
  }

  /// A locate that never produced a position leaves nothing to show — the
  /// previous session's Hotels are dropped rather than left sitting behind
  /// a permission state, where a later transition could surface a list that
  /// no longer matches either the query or the position.
  void _failLocate(NearbyHotelsState next, {String? message}) {
    _latitude = null;
    _longitude = null;
    hotels = [];
    errorMessage = message;
    state = next;
    notifyListeners();
  }

  /// Narrows the already-located Nearby list by Hotel name/address.
  ///
  /// Deliberately does not trigger a locate of its own: this is called for
  /// every keystroke pause from the Discover search box, whichever tab is
  /// showing, and asking for GPS permission because someone typed in a
  /// search box would be a permission prompt they never asked for. The
  /// query is remembered instead ([pendingSearch]) and applied by the next
  /// [load] — the one the Near You tab runs when it is actually opened —
  /// so the tab is never shown unfiltered results for a live query.
  Future<void> search(String query) async {
    if (query == _search) return;
    _search = query;
    if (!hasLocation) return;
    await _fetch(requestId: ++_requestId);
  }

  Future<void> _fetch({required int requestId}) async {
    state = NearbyHotelsState.loading;
    notifyListeners();
    try {
      final result = await repository.getNearbyHotels(
        latitude: _latitude!,
        longitude: _longitude!,
        search: _search,
      );
      if (requestId != _requestId) return;
      hotels = result;
      state = hotels.isEmpty ? NearbyHotelsState.empty : NearbyHotelsState.loaded;
    } catch (_) {
      if (requestId != _requestId) return;
      hotels = [];
      errorMessage = 'Could not load nearby Hotels. Please try again.';
      state = NearbyHotelsState.error;
    }
    notifyListeners();
  }

  Future<void> openAppSettings() => locationService.openAppSettings();

  Future<void> openLocationSettings() => locationService.openLocationSettings();
}
