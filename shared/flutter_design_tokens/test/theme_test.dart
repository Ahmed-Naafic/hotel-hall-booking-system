import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HHColors', () {
    test('ports the brand scale hex values exactly (colors.css)', () {
      expect(HHColors.navy700, const Color(0xFF0C2A4E));
      expect(HHColors.teal700, const Color(0xFF187884));
      expect(HHColors.gold600, const Color(0xFFCC9C24));
    });

    test('semantic aliases resolve to the same brand-scale values as the source CSS', () {
      expect(HHColors.textHeading, HHColors.navy700);
      expect(HHColors.actionAccent, HHColors.teal700);
      expect(HHColors.surfacePage, HHColors.ivory);
    });
  });

  group('HHSpacing', () {
    test('follows the 4px base scale (spacing.css)', () {
      expect(HHSpacing.space1, 4);
      expect(HHSpacing.space5, 16);
      expect(HHSpacing.space14, 128);
    });
  });

  group('HHRadii', () {
    test('ports the radius scale (radii.css)', () {
      expect(HHRadii.lg, 10);
      expect(HHRadii.pill, 999);
      expect(HHRadii.card, HHRadii.lg);
    });
  });

  group('HHMotion', () {
    test('ports durations and easing curves (motion.css)', () {
      expect(HHMotion.durFast, const Duration(milliseconds: 140));
      expect(HHMotion.easeStandard, const Cubic(0.2, 0.6, 0.2, 1));
    });
  });

  group('emToPx', () {
    test('converts em tracking to logical pixels relative to font size', () {
      expect(emToPx(0.04, 20), closeTo(0.8, 0.0001));
      expect(emToPx(0, 20), 0);
    });
  });

  group('buildHotelHallTheme', () {
    test('builds a complete, usable ThemeData', () {
      final theme = buildHotelHallTheme();
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.primary, HHColors.actionPrimary);
      expect(theme.scaffoldBackgroundColor, HHColors.surfacePage);
      expect(theme.textTheme.bodyLarge, isNotNull);
    });

    test('carries the palette matching its brightness, so context.hh resolves', () {
      final light = buildHotelHallTheme();
      final dark = buildHotelHallTheme(brightness: Brightness.dark);

      expect(light.extension<HHPalette>()?.surfacePage, HHPalette.light.surfacePage);
      expect(dark.extension<HHPalette>()?.surfacePage, HHPalette.dark.surfacePage);
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, HHPalette.dark.surfacePage);
    });

    test('recolours the type scale for the dark theme', () {
      // HHTypography bakes the light heading/body colours into every style;
      // a dark theme that skipped this would render dark navy text on a dark
      // page.
      final dark = buildHotelHallTheme(brightness: Brightness.dark);
      expect(dark.textTheme.bodyLarge?.color, HHPalette.dark.textBody);
      expect(dark.textTheme.displaySmall?.color, HHPalette.dark.textHeading);
    });
  });
}
