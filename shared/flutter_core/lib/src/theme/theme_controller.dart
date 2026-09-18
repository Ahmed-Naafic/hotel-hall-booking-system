import 'package:flutter/material.dart';

import '../auth/session_store.dart';

/// The chosen colour theme, persisted across launches.
///
/// Flutter's own [ThemeMode] is exactly the three-way choice this needs, so
/// there is no parallel enum: `system` is a standing instruction to follow
/// the device, and `MaterialApp` re-resolves it whenever the OS flips. The
/// preference is what gets stored, never the resolved brightness — storing
/// the resolved value would freeze a device that later changes its setting.
///
/// Persisted through [TokenStorage], the same plain key-value seam
/// `SessionStore` uses. A theme preference is not a secret, but reusing the
/// existing seam keeps this testable with the same in-memory fake and adds
/// no dependency for one small value.
class ThemeController extends ChangeNotifier {
  ThemeController({TokenStorage? storage}) : _storage = storage ?? const SecureTokenStorage();

  final TokenStorage _storage;

  static const _modeKey = 'hh_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// Reads the stored preference. Following the device is the right default
  /// both before this runs and if reading fails.
  Future<void> load() async {
    try {
      final stored = await _storage.read(_modeKey);
      final restored = _parse(stored);
      if (restored == _mode) return;
      _mode = restored;
      notifyListeners();
    } catch (_) {
      // Keep ThemeMode.system.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    // Applied first: the theme should change on tap, not after a write.
    notifyListeners();
    try {
      await _storage.write(_modeKey, mode.name);
    } catch (_) {
      // Not being able to remember the choice must not stop us applying it.
    }
  }

  static ThemeMode _parse(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
