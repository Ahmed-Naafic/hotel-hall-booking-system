import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../data/hall_models.dart';
import '../data/hall_repository.dart';

/// Drives both Create and Edit, using the structured Hall Profile model
/// `BDR-016` (Approved 2026-08-26, resolving former Pending Business
/// Decision #2) defines: required standard fields (Hall Name, Capacity),
/// optional standard fields (Description, Location/Area), and optional
/// custom key/value fields that can never substitute for a required one.
///
/// Both Create and Edit resubmit the full visible standard-field set on
/// every save (not a diff of only what changed) — the same approach
/// `HotelProfileFormController` uses for Hotel Profile, chosen for the same
/// reason: the structured form always shows every standard field's current
/// value, so "save" naturally means "persist what's on screen." The
/// backend's `PATCH` still merges rather than replaces `profileData`
/// (`profile.service.js#updateHallProfile`), so a removed custom field
/// cannot be expressed by this form — `HallProfileDataEditor` only supports
/// add/edit values, not deletion, for exactly this reason.
class HallFormController extends ChangeNotifier {
  HallFormController({required this.repository, required this.hotelId, this.existingHall});

  final HallRepository repository;
  final String hotelId;
  final Hall? existingHall;

  bool get isEditing => existingHall != null;

  /// The standard field keys `BDR-016` defines — reserved. A custom
  /// "Additional Information" field using one of these names is rejected
  /// before any request is sent, so a custom field can never satisfy or
  /// replace a required standard field, per `BDR-016`'s explicit rule.
  static const standardFieldKeys = {'name', 'capacity', 'description', 'location'};

  bool isBusy = false;
  String? errorMessage;

  Future<Hall?> submit({
    required Map<String, dynamic> standardFields,
    required Map<String, dynamic> customFields,
  }) async {
    final reservedCollisions = customFields.keys.where(standardFieldKeys.contains).toList();
    if (reservedCollisions.isNotEmpty) {
      errorMessage =
          'Additional Information cannot reuse a standard field name (${reservedCollisions.join(', ')}) — '
          'a custom field can never replace a required field.';
      notifyListeners();
      return null;
    }

    isBusy = true;
    errorMessage = null;
    notifyListeners();

    final profileData = {...standardFields, ...customFields};
    try {
      final hall = isEditing
          ? await repository.updateHall(hotelId: hotelId, id: existingHall!.id, profileData: profileData)
          : await repository.createHall(hotelId: hotelId, profileData: profileData);
      isBusy = false;
      notifyListeners();
      return hall;
    } on ApiException catch (e) {
      isBusy = false;
      errorMessage = e.message;
      notifyListeners();
      return null;
    } on NetworkException catch (e) {
      isBusy = false;
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }
}
