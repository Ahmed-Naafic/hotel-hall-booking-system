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
  });

  final DiscoveryRepository repository;
  final LocationService locationService;

  NearbyHotelsState state = NearbyHotelsState.locating;
  List<NearbyHotel> hotels = [];
  String? errorMessage;

  Future<void> load() async {
    state = NearbyHotelsState.locating;
    errorMessage = null;
    notifyListeners();

    final location = await locationService.getCurrentLocation();

    switch (location.outcome) {
      case LocationOutcome.permissionDenied:
        state = NearbyHotelsState.permissionDenied;
        notifyListeners();
        return;
      case LocationOutcome.permissionDeniedForever:
        state = NearbyHotelsState.permissionDeniedForever;
        notifyListeners();
        return;
      case LocationOutcome.serviceDisabled:
        state = NearbyHotelsState.serviceDisabled;
        notifyListeners();
        return;
      case LocationOutcome.error:
        state = NearbyHotelsState.error;
        errorMessage = 'Could not determine your location. Please try again.';
        notifyListeners();
        return;
      case LocationOutcome.granted:
        break;
    }

    state = NearbyHotelsState.loading;
    notifyListeners();
    try {
      hotels = await repository.getNearbyHotels(
        latitude: location.latitude!,
        longitude: location.longitude!,
      );
      state = hotels.isEmpty ? NearbyHotelsState.empty : NearbyHotelsState.loaded;
    } catch (_) {
      errorMessage = 'Could not load nearby Hotels. Please try again.';
      state = NearbyHotelsState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> openAppSettings() => locationService.openAppSettings();

  Future<void> openLocationSettings() => locationService.openLocationSettings();
}
