import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

import '../data/hotel_repository.dart';
import 'hotel_context_controller.dart';

/// Drives the structured Hotel profile-completion form (HM2, `BR-HOTEL-02`)
/// — `PATCH /hotels/:id` while the Hotel is `REGISTERED`. Profile content is
/// no longer unconstrained: `BDR-015` (Required Hotel Business-Profile
/// Content, `Approved` 2026-08-26) defines a hybrid model — required
/// standard fields, optional standard fields, and optional Hotel
/// Manager-defined custom fields that may never substitute for a required
/// one. No new backend endpoint or request shape: `profileData` remains a
/// single flat JSON object (`hotel_repository.dart#completeProfile`); this
/// controller is what now gives that object a defined minimum key set.
///
/// Operates only on the Hotel Manager's own Hotel, resolved through
/// `hotelContext` — this form has no way to target any Hotel other than the
/// one `HotelContextController` already resolved for the authenticated
/// caller (never an arbitrary Hotel id).
class HotelProfileFormController extends ChangeNotifier {
  HotelProfileFormController({required this.repository, required this.hotelContext});

  final HotelRepository repository;
  final HotelContextController hotelContext;

  /// The standard field keys `BDR-015` defines (Hotel Name, Description,
  /// Location, Contact Phone, Email) — reserved. A custom "Additional
  /// Information" field using one of these names is rejected before any
  /// request is sent, so a custom field can never satisfy or replace a
  /// required standard field, per `BDR-015`'s explicit rule.
  static const standardFieldKeys = {'name', 'description', 'location', 'contactPhone', 'email'};

  bool isBusy = false;
  String? errorMessage;

  /// [standardFields] must already be validated by the caller (required
  /// keys present and non-empty — enforced by the form's own `Form`
  /// validators before this is ever called); this method's own
  /// responsibility is the one rule the form's per-field validators cannot
  /// express: a custom field must never reuse a reserved standard key.
  Future<bool> submitProfile({
    required Map<String, dynamic> standardFields,
    required Map<String, dynamic> customFields,
  }) async {
    final reservedCollisions = customFields.keys.where(standardFieldKeys.contains).toList();
    if (reservedCollisions.isNotEmpty) {
      errorMessage =
          'Additional Information cannot reuse a standard field name (${reservedCollisions.join(', ')}) — '
          'a custom field can never replace a required field.';
      notifyListeners();
      return false;
    }

    final hotel = hotelContext.hotel;
    if (hotel == null) {
      errorMessage = 'No Hotel is connected to this account yet.';
      notifyListeners();
      return false;
    }

    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = await repository.completeProfile(hotel.id, {...standardFields, ...customFields});
      hotelContext.setHotel(updated);
      isBusy = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isBusy = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      isBusy = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
