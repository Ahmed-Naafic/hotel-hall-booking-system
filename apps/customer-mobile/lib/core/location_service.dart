import 'package:geolocator/geolocator.dart';

/// The outcome of a [LocationService.getCurrentLocation] attempt. Nearby
/// Hotels (approved V1 business rules) needs to tell these cases apart so it
/// can show a permission-specific message/action rather than a generic
/// error, while normal Hotel/Hall browsing never touches this at all.
enum LocationOutcome {
  granted,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  error,
}

class LocationResult {
  const LocationResult({required this.outcome, this.latitude, this.longitude});

  final LocationOutcome outcome;
  final double? latitude;
  final double? longitude;
}

/// The only file in this app that imports `package:geolocator` — every
/// other layer (controller, screen) talks to [LocationResult] /
/// [LocationOutcome] only, so the platform package stays swappable and
/// mockable in tests without a plugin channel.
class LocationService {
  const LocationService();

  Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(outcome: LocationOutcome.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult(outcome: LocationOutcome.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          outcome: LocationOutcome.permissionDeniedForever,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return LocationResult(
        outcome: LocationOutcome.granted,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const LocationResult(outcome: LocationOutcome.error);
    }
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
