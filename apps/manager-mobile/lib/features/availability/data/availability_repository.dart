import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'availability_models.dart';

/// One function per own-Hotel-scoped Availability endpoint actually
/// implemented (Approved Implementation Plan) —
/// `GET`/`POST`/`PATCH`/`DELETE /hotels/:hotelId/halls/:hallId/availability/blocks[/:id]`.
/// `date`/`startTime`/`endTime` are sent as plain Mogadishu wall-clock
/// strings (`YYYY-MM-DD`/`HH:mm`) exactly as picked — the fixed +03:00
/// conversion to an absolute instant is entirely the backend's job
/// (Approved Technical Design §4); this app never does timezone math.
class AvailabilityRepository {
  AvailabilityRepository(this._client);

  final ApiClient _client;

  Future<List<AvailabilityBlock>> listBlocks({
    required String hotelId,
    required String hallId,
    required String date,
  }) async {
    final data = await _client.get(
      '/hotels/$hotelId/halls/$hallId/availability/blocks',
      query: {'date': date},
    ) as List<dynamic>;
    return data
        .map((item) => AvailabilityBlock.fromJson((item as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<AvailabilityBlock> createBlock({
    required String hotelId,
    required String hallId,
    required String date,
    required String startTime,
    required String endTime,
    String? reason,
  }) async {
    final data = await _client.post(
      '/hotels/$hotelId/halls/$hallId/availability/blocks',
      body: {'date': date, 'startTime': startTime, 'endTime': endTime, if (reason != null) 'reason': reason},
    );
    return AvailabilityBlock.fromJson(data as Map<String, dynamic>);
  }

  Future<AvailabilityBlock> updateBlock({
    required String hotelId,
    required String hallId,
    required String blockId,
    String? date,
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    final data = await _client.patch(
      '/hotels/$hotelId/halls/$hallId/availability/blocks/$blockId',
      body: {
        if (date != null) 'date': date,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (reason != null) 'reason': reason,
      },
    );
    return AvailabilityBlock.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteBlock({
    required String hotelId,
    required String hallId,
    required String blockId,
  }) => _client.delete('/hotels/$hotelId/halls/$hallId/availability/blocks/$blockId');
}
