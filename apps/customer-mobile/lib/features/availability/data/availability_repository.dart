import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'availability_models.dart';

/// The two public Availability endpoints a Customer ever calls (Approved
/// Implementation Plan, decision 1: no booking-creation endpoint exists
/// yet). `date`/`startTime`/`endTime` are sent as plain Mogadishu
/// wall-clock strings exactly as picked — this app never does timezone
/// math, matching Manager Mobile's identical repository.
class AvailabilityRepository {
  AvailabilityRepository(this._client);

  final ApiClient _client;

  Future<List<BusyPeriod>> getAvailability({required String hallId, required String date}) async {
    final data = await _client.get('/halls/$hallId/availability', query: {'date': date}) as Map<String, dynamic>;
    return (data['busyPeriods'] as List<dynamic>)
        .map((item) => BusyPeriod.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  /// The authoritative, backend-final check — the only source of truth for
  /// whether a selected period is actually bookable (Approved Technical
  /// Design §8/§11). Never trust `getAvailability`'s display data for this
  /// decision.
  Future<bool> checkAvailability({
    required String hallId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final data = await _client.post(
      '/halls/$hallId/availability/check',
      body: {'date': date, 'startTime': startTime, 'endTime': endTime},
    ) as Map<String, dynamic>;
    return data['available'] as bool;
  }
}
