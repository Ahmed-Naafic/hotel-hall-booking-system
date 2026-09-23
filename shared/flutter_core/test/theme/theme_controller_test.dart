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

    test('the auth hero panel stays deeper than the card that overlaps it', () {
      // The login card sits on the hero's bottom edge. If the panel ends
      // lighter than the card, the card recedes into it and its rounded
      // edge disappears — which is what a hardcoded navy700 gradient did in
      // dark mode, where the card is navy800.
      for (final palette in [HHPalette.light, HHPalette.dark]) {
        expect(
          palette.surfaceHeroBottom.computeLuminance(),
          lessThan(palette.surfaceCard.computeLuminance()),
          reason: 'the card must read as raised above the hero panel',
        );
        expect(
          palette.surfaceHeroBottom.computeLuminance(),
          lessThan(palette.surfaceHeroTop.computeLuminance()),
          reason: 'the panel is lit at the crown and deepens toward the card',
        );
      }
    });

    test('the primary action is gold in dark and navy in light', () {
      // The approved dark direction: dark mode's page *is* navy, so the
      // CTA cannot also be navy. Light keeps navy, where it is the
      // strongest mark on an ivory page.
      expect(HHPalette.dark.actionCta, HHColors.gold500);
      expect(HHPalette.light.actionCta, HHColors.navy700);
      // Whatever the fill, the label on it has to be legible.
      for (final palette in [HHPalette.light, HHPalette.dark]) {
        final gap =
            (palette.onActionCta.computeLuminance() - palette.actionCta.computeLuminance()).abs();
        expect(gap, greaterThan(0.4), reason: 'the CTA label must stand off its own fill');
      }
    });

    test('the structural navy is NOT the call-to-action colour', () {
      // These are separate roles on purpose. Collapsing them is what would
      // turn chat bubbles, unread dots and selected segments gold too.
      expect(HHPalette.dark.actionPrimary, isNot(HHPalette.dark.actionCta));
      expect(HHPalette.dark.actionPrimary, HHColors.navy500);
    });

    test('dark mode carries no teal accent', () {
      // The approved dark design is navy, gold and neutrals only — every
      // accent mark in it is gold. Light mode keeps teal.
      for (final role in [
        HHPalette.dark.actionAccent,
        HHPalette.dark.textAccent,
        HHPalette.dark.textLink,
        HHPalette.dark.focusRing,
      ]) {
        expect(
          role.b < role.r,
          isTrue,
          reason: 'a dark-mode accent should be gold (warm), not teal (cool): $role',
        );
      }
      expect(HHPalette.light.textLink, HHColors.teal700);
    });

    test('the gold call-to-action keeps the design\'s own two stops', () {
      // Sampled from the approved dark login design. Pinned because the
      // nearest pair on the `gold*` scale is a visibly flatter sweep, and
      // "tidying" these into scale values is exactly the change that would
      // quietly undo it.
      for (final palette in [HHPalette.light, HHPalette.dark]) {
        expect(palette.actionGoldGradientFrom, const Color(0xFFEFC762));
        expect(palette.actionGoldGradientTo, const Color(0xFFB17E32));
      }
    });

    test('a text field never dissolves into the surface it sits on', () {
      // Fields are translucent lifts, so what matters is the composite
      // against their two real grounds — a card (most forms) and the page.
      for (final palette in [HHPalette.light, HHPalette.dark]) {
        for (final ground in [palette.surfaceCard, palette.surfacePage]) {
          final filled = Color.alphaBlend(palette.surfaceField, ground);
          expect(
            filled,
            isNot(ground),
            reason: 'an input filled with its own background is an invisible input',
          );
        }
      }
    });

    test('body text contrasts its own page in both themes', () {
      for (final palette in [HHPalette.light, HHPalette.dark]) {
        final gap = (palette.textBody.computeLuminance() - palette.surfacePage.computeLuminance()).abs();
        expect(gap, greaterThan(0.5), reason: 'text must stand off the page it sits on');
      }
    });
  });
}
