import 'package:flutter/foundation.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';

/// Whether this device should receive push notifications — a local,
/// per-device preference. Mirrors `ThemeController`'s own shape and
/// rationale exactly: persisted through `TokenStorage`, not a secret, but
/// reusing the existing seam keeps this testable with the same in-memory
/// fake and adds no dependency for one small value.
///
/// Distinct from Notification V1's own server-side Notification list/unread
/// state (`NotificationController`) — this only decides whether *this
/// device* keeps a registered push token, never whether a Notification is
/// created or persisted (Business Specification: push is a delivery
/// mechanism, never the record of whether something "happened").
class NotificationPreferenceController extends ChangeNotifier {
  NotificationPreferenceController({TokenStorage? storage}) : _storage = storage ?? const SecureTokenStorage();

  final TokenStorage _storage;

  static const _key = 'hh_push_notifications_enabled';

  bool _enabled = true;
  bool get enabled => _enabled;

  /// Reads the stored preference. Enabled is the right default both before
  /// this runs and if reading fails — a device that never receives a
  /// Notification is a worse failure mode than one that keeps receiving
  /// them until this loads.
  Future<void> load() async {
    try {
      final stored = await _storage.read(_key);
      final restored = stored != 'false';
      if (restored == _enabled) return;
      _enabled = restored;
      notifyListeners();
    } catch (_) {
      // Keep enabled.
    }
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    // Applied first: the switch should flip on tap, not after a write.
    notifyListeners();
    try {
      await _storage.write(_key, value.toString());
    } catch (_) {
      // Not being able to remember the choice must not stop it applying.
    }
  }
}
