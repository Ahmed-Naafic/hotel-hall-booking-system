import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../data/availability_models.dart';
import '../data/availability_repository.dart';

enum AvailabilityStatus { loading, ready, error }

String formatDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Loads one Hall's busy periods for one selected (Mogadishu-calendar)
/// date, and performs the authoritative pre-submission check. Mirrors
/// Manager Mobile's own `AvailabilityController` shape.
class AvailabilityController extends ChangeNotifier {
  AvailabilityController({
    required this.repository,
    required this.hallId,
    DateTime? initialDate,
  }) : selectedDate = initialDate ?? DateTime.now();

  final AvailabilityRepository repository;
  final String hallId;

  AvailabilityStatus status = AvailabilityStatus.loading;
  List<BusyPeriod> busyPeriods = [];
  DateTime selectedDate;
  String? errorMessage;

  bool isChecking = false;
  String? checkErrorMessage;

  Future<void> load() async {
    status = AvailabilityStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      busyPeriods = await repository.getAvailability(hallId: hallId, date: formatDateKey(selectedDate));
      status = AvailabilityStatus.ready;
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

  /// The authoritative, backend-final re-validation (rule 12) — never
  /// derived from `busyPeriods`, which is informational only (rule 11).
  /// Returns `true`/`false` on a definitive answer; `null` on a request
  /// failure, with `checkErrorMessage` set for the caller to show.
  Future<bool?> submitCheck({required String startTime, required String endTime}) async {
    isChecking = true;
    checkErrorMessage = null;
    notifyListeners();

    try {
      final available = await repository.checkAvailability(
        hallId: hallId,
        date: formatDateKey(selectedDate),
        startTime: startTime,
        endTime: endTime,
      );
      isChecking = false;
      notifyListeners();
      return available;
    } on ApiException catch (e) {
      checkErrorMessage = e.message;
      isChecking = false;
      notifyListeners();
      return null;
    } on NetworkException catch (e) {
      checkErrorMessage = e.message;
      isChecking = false;
      notifyListeners();
      return null;
    }
  }
}
