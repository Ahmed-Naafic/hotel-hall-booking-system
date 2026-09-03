import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../data/availability_models.dart';
import '../data/availability_repository.dart';

enum AvailabilityStatus { loading, empty, ready, error }

String formatDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Mogadishu is a fixed UTC+3 offset, no DST (Approved Technical Design
/// §4) — the calendar date a stored UTC instant falls on, in Mogadishu
/// terms, is always `utc + 3h`'s own date, never the device's own
/// `.toLocal()` timezone.
DateTime mogadishuDateOnly(DateTime utcInstant) {
  final local = utcInstant.toUtc().add(const Duration(hours: 3));
  return DateTime(local.year, local.month, local.day);
}

/// Loads and mutates one Hall's availability blocks for one selected
/// (Mogadishu-calendar) date — the Manager's day-view. Mirrors
/// `HallListController`'s shape (a status enum, a local `upsert`/remove
/// after a mutation rather than a full reload).
class AvailabilityController extends ChangeNotifier {
  AvailabilityController({
    required this.repository,
    required this.hotelId,
    required this.hallId,
    DateTime? initialDate,
  }) : selectedDate = initialDate ?? DateTime.now();

  final AvailabilityRepository repository;
  final String hotelId;
  final String hallId;

  AvailabilityStatus status = AvailabilityStatus.loading;
  List<AvailabilityBlock> blocks = [];
  DateTime selectedDate;
  String? errorMessage;

  Future<void> load() async {
    status = AvailabilityStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.listBlocks(
        hotelId: hotelId,
        hallId: hallId,
        date: formatDateKey(selectedDate),
      );
      blocks = result;
      status = blocks.isEmpty ? AvailabilityStatus.empty : AvailabilityStatus.ready;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = AvailabilityStatus.error;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      status = AvailabilityStatus.error;
    }
    notifyListeners();
  }

  Future<void> changeDate(DateTime date) async {
    selectedDate = date;
    await load();
  }

  /// Called after `BlockFormScreen` (which owns the actual create/update
  /// API call itself, matching `HallFormScreen`'s established pattern) pops
  /// with the resulting block.
  ///
  /// A block's own period — picked independently in the form, never
  /// constrained to match whatever day was showing when the form opened —
  /// can land on a different Mogadishu calendar date than `selectedDate`
  /// (e.g. viewing today, creating a block for next week). Blindly
  /// appending it to the in-memory `blocks` list would make it appear to
  /// belong to the day currently on screen, which it doesn't. When the
  /// dates differ, this switches the view to the block's own date and
  /// reloads authoritatively instead of merging two days' data locally.
  ///
  /// Only `block.startsAt` — a real UTC instant from the server — goes
  /// through `mogadishuDateOnly`. `selectedDate` is always a plain calendar
  /// date (from the device-local date picker, used everywhere else via its
  /// raw y/m/d — see `formatDateKey`), never a UTC instant; running it
  /// through the same conversion would make this comparison depend on the
  /// device's own timezone offset instead of the fixed Mogadishu +03:00,
  /// which could silently reintroduce the exact cross-day mixing this
  /// method exists to prevent on any device not itself set to UTC+3.
  Future<void> upsert(AvailabilityBlock block) async {
    final blockDate = mogadishuDateOnly(block.startsAt);
    final viewedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    if (blockDate != viewedDate) {
      await changeDate(blockDate);
      return;
    }
    final index = blocks.indexWhere((b) => b.id == block.id);
    if (index == -1) {
      blocks = [...blocks, block];
    } else {
      blocks = [...blocks]..[index] = block;
    }
    blocks.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    status = AvailabilityStatus.ready;
    notifyListeners();
  }

  Future<void> deleteBlock(String blockId) async {
    await repository.deleteBlock(hotelId: hotelId, hallId: hallId, blockId: blockId);
    blocks = blocks.where((b) => b.id != blockId).toList();
    status = blocks.isEmpty ? AvailabilityStatus.empty : AvailabilityStatus.ready;
    notifyListeners();
  }
}
