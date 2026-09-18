import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

import '../auth/in_memory_token_storage.dart';

/// A storage that always throws — private browsing / blocked storage, where
/// the preference cannot be remembered but must still apply.
class _FailingStorage implements TokenStorage {
  @override
  Future<void> write(String key, String value) async => throw StateError('no storage');
  @override
  Future<String?> read(String key) async => throw StateError('no storage');
  @override
  Future<void> delete(String key) async => throw StateError('no storage');
}

void main() {
  group('ThemeController', () {
    test('follows the device until told otherwise', () {
      expect(ThemeController(storage: InMemoryTokenStorage()).mode, ThemeMode.system);
    });

    test('remembers an explicit choice across a restart', () async {
      final storage = InMemoryTokenStorage();
      await ThemeController(storage: storage).setMode(ThemeMode.dark);

      final restarted = ThemeController(storage: storage);
      await restarted.load();
      expect(restarted.mode, ThemeMode.dark);
    });

    test('stores the preference, not the resolved brightness, so system keeps following', () async {
      final storage = InMemoryTokenStorage();
      final controller = ThemeController(storage: storage);
      await controller.setMode(ThemeMode.dark);
      await controller.setMode(ThemeMode.system);

      final restarted = ThemeController(storage: storage);
      await restarted.load();
      expect(restarted.mode, ThemeMode.system);
    });

    test('notifies listeners so MaterialApp rebuilds', () async {
      final controller = ThemeController(storage: InMemoryTokenStorage());
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.setMode(ThemeMode.dark);
      expect(notified, 1);

      // Re-selecting the same mode changes nothing, so nothing rebuilds.
      await controller.setMode(ThemeMode.dark);
      expect(notified, 1);
    });

    test('still applies a choice when the preference cannot be stored', () async {
      final controller = ThemeController(storage: _FailingStorage());
      await controller.setMode(ThemeMode.light);
      expect(controller.mode, ThemeMode.light);
    });

    test('falls back to following the device when the stored value is unreadable', () async {
      final controller = ThemeController(storage: _FailingStorage());
      await controller.load();
      expect(controller.mode, ThemeMode.system);
    });
  });

  group('HHPalette', () {
    test('every role differs between light and dark where it must', () {
      expect(HHPalette.light.surfacePage, isNot(HHPalette.dark.surfacePage));
      expect(HHPalette.light.textBody, isNot(HHPalette.dark.textBody));
      expect(HHPalette.light.actionPrimary, isNot(HHPalette.dark.actionPrimary));
    });

    test('the dark page sits beneath its own cards, so elevation reads', () {
      // A dark theme inverts the ramp: the page is the darkest layer.
      expect(HHPalette.dark.surfacePage.computeLuminance(),
          lessThan(HHPalette.dark.surfaceCard.computeLuminance()));
      expect(HHPalette.dark.surfaceCard.computeLuminance(),
          lessThan(HHPalette.dark.surfaceRaised.computeLuminance()));
      // Light runs the other way — cards sit above a tinted page.
      expect(HHPalette.light.surfacePage.computeLuminance(),
          lessThan(HHPalette.light.surfaceCard.computeLuminance()));
    });

    test('body text contrasts its own page in both themes', () {
      for (final palette in [HHPalette.light, HHPalette.dark]) {
        final gap = (palette.textBody.computeLuminance() - palette.surfacePage.computeLuminance()).abs();
        expect(gap, greaterThan(0.5), reason: 'text must stand off the page it sits on');
      }
    });
  });
}
