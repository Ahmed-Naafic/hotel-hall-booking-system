import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'palette.dart';
import 'radii.dart';
import 'spacing.dart';
import 'typography.dart';

/// Builds the shared `ThemeData` both mobile apps (Customer, Hotel
/// Manager) consume — the concrete deliverable of FE-00. Assembled
/// entirely from the token files in this package; no color, size, or
/// font choice is made ad hoc here that isn't already a named token.
///
/// Both brightnesses are built from the same token set — `HHPalette`
/// resolves every semantic colour for the requested one, and the extension
/// it registers is what lets widgets read those same roles through
/// `context.hh` rather than compiling in a light value.
ThemeData buildHotelHallTheme({Brightness brightness = Brightness.light}) {
  final palette = brightness == Brightness.dark ? HHPalette.dark : HHPalette.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: HHColors.navy700,
    brightness: brightness,
    primary: palette.actionPrimary,
    onPrimary: palette.textInverse,
    secondary: palette.actionAccent,
    onSecondary: palette.textInverse,
    tertiary: palette.actionGold,
    onTertiary: HHColors.navy900,
    error: palette.danger500,
    onError: palette.textInverse,
    surface: palette.surfaceCard,
    onSurface: palette.textBody,
  );

  final textTheme = TextTheme(
    displayLarge: HHTypography.displayXl,
    displayMedium: HHTypography.displayLg,
    displaySmall: HHTypography.displayMd,
    headlineLarge: HHTypography.displaySm,
    headlineMedium: HHTypography.serifLg,
    headlineSmall: HHTypography.serifMd,
    titleLarge: HHTypography.serifSm,
    titleMedium: HHTypography.textXl,
    titleSmall: HHTypography.textLg,
    bodyLarge: HHTypography.textMd,
    bodyMedium: HHTypography.textSm,
    bodySmall: HHTypography.textXs,
    labelLarge: GoogleFonts.jost(
      fontSize: HHTypeScale.textSm,
      fontWeight: HHTypeScale.weightMedium,
      color: palette.textBody,
    ),
    labelMedium: HHTypography.textXs,
    labelSmall: HHTypography.text2xs,
    // `HHTypography` bakes the light text colours into every style, since a
    // TextStyle has to carry one. Re-colouring the assembled theme here is
    // what keeps a single set of type tokens serving both brightnesses —
    // `apply` recolours the display/headline group and the body group, which
    // is exactly the heading/body split the tokens already draw.
  ).apply(
    displayColor: palette.textHeading,
    bodyColor: palette.textBody,
  );

  return ThemeData(
    useMaterial3: true,
    extensions: [palette],
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.surfacePage,
    textTheme: textTheme,
    fontFamily: GoogleFonts.jost().fontFamily,
    dividerColor: palette.borderSubtle,
    focusColor: palette.focusRing,
    cardTheme: CardThemeData(
      color: palette.surfaceCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.card)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surfaceNavy,
      foregroundColor: palette.textInverse,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: HHTypography.displaySm.copyWith(color: palette.textInverse, fontSize: HHTypeScale.textXl),
    ),
    // Material 3's default FAB otherwise falls back to an auto-derived
    // tonal `secondaryContainer` color — a muted lavender no `HHColors`
    // token defines — rather than any of the three approved brand colors.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.actionPrimary,
      foregroundColor: palette.textInverse,
      extendedTextStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, fontWeight: HHTypeScale.weightMedium),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.actionPrimary,
        foregroundColor: palette.textInverse,
        disabledBackgroundColor: palette.actionDisabledBg,
        disabledForegroundColor: palette.actionDisabledText,
        minimumSize: const Size.fromHeight(HHSpacing.controlHMd),
        padding: const EdgeInsets.symmetric(horizontal: HHSpacing.controlPadX),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.control)),
        textStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, fontWeight: HHTypeScale.weightMedium),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.actionPrimary,
        side: BorderSide(color: palette.borderDefault),
        minimumSize: const Size.fromHeight(HHSpacing.controlHMd),
        padding: const EdgeInsets.symmetric(horizontal: HHSpacing.controlPadX),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.control)),
        textStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, fontWeight: HHTypeScale.weightMedium),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: HHSpacing.controlPadX, vertical: HHSpacing.space4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HHRadii.control),
        borderSide: BorderSide(color: palette.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HHRadii.control),
        borderSide: BorderSide(color: palette.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HHRadii.control),
        borderSide: BorderSide(color: palette.focusRing, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HHRadii.control),
        borderSide: BorderSide(color: palette.danger500),
      ),
      labelStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, color: palette.textMuted),
      hintStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, color: palette.textSubtle),
    ),
    dividerTheme: DividerThemeData(color: palette.borderSubtle, thickness: 1, space: HHSpacing.space8),
  );
}
