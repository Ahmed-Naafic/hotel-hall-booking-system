import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'radii.dart';
import 'spacing.dart';
import 'typography.dart';

/// Builds the shared `ThemeData` both mobile apps (Customer, Hotel
/// Manager) consume — the concrete deliverable of FE-00. Assembled
/// entirely from the token files in this package; no color, size, or
/// font choice is made ad hoc here that isn't already a named token.
///
/// The source design system (`Hotel Hall Design System/tokens/*.css`) has
/// no dark-mode token set — only the light palette exists, so only a
/// light `ThemeData` is built. A dark theme is future, additive scope,
/// not invented here.
ThemeData buildHotelHallTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: HHColors.navy700,
    brightness: Brightness.light,
    primary: HHColors.actionPrimary,
    onPrimary: HHColors.textInverse,
    secondary: HHColors.actionAccent,
    onSecondary: HHColors.textInverse,
    tertiary: HHColors.actionGold,
    onTertiary: HHColors.navy900,
    error: HHColors.danger500,
    onError: HHColors.textInverse,
    surface: HHColors.surfaceCard,
    onSurface: HHColors.textBody,
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
      color: HHColors.textBody,
    ),
    labelMedium: HHTypography.textXs,
    labelSmall: HHTypography.text2xs,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: HHColors.surfacePage,
    textTheme: textTheme,
    fontFamily: GoogleFonts.jost().fontFamily,
    dividerColor: HHColors.borderSubtle,
    focusColor: HHColors.focusRing,
    cardTheme: CardThemeData(
      color: HHColors.surfaceCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.card)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: HHColors.surfaceNavy,
      foregroundColor: HHColors.textInverse,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: HHTypography.displaySm.copyWith(color: HHColors.textInverse, fontSize: HHTypeScale.textXl),
    ),
    // Material 3's default FAB otherwise falls back to an auto-derived
    // tonal `secondaryContainer` color — a muted lavender no `HHColors`
    // token defines — rather than any of the three approved brand colors.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: HHColors.actionPrimary,
      foregroundColor: HHColors.textInverse,
      extendedTextStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, fontWeight: HHTypeScale.weightMedium),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HHColors.actionPrimary,
        foregroundColor: HHColors.textInverse,
        disabledBackgroundColor: HHColors.actionDisabledBg,
        disabledForegroundColor: HHColors.actionDisabledText,
        minimumSize: const Size.fromHeight(HHSpacing.controlHMd),
        padding: const EdgeInsets.symmetric(horizontal: HHSpacing.controlPadX),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.control)),
        textStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, fontWeight: HHTypeScale.weightMedium),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HHColors.actionPrimary,
        side: const BorderSide(color: HHColors.borderDefault),
        minimumSize: const Size.fromHeight(HHSpacing.controlHMd),
        padding: const EdgeInsets.symmetric(horizontal: HHSpacing.controlPadX),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.control)),
        textStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, fontWeight: HHTypeScale.weightMedium),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HHColors.surfaceCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: HHSpacing.controlPadX, vertical: HHSpacing.space4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HHRadii.control),
        borderSide: const BorderSide(color: HHColors.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HHRadii.control),
        borderSide: const BorderSide(color: HHColors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HHRadii.control),
        borderSide: const BorderSide(color: HHColors.focusRing, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HHRadii.control),
        borderSide: const BorderSide(color: HHColors.danger500),
      ),
      labelStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, color: HHColors.textMuted),
      hintStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, color: HHColors.textSubtle),
    ),
    dividerTheme: const DividerThemeData(color: HHColors.borderSubtle, thickness: 1, space: HHSpacing.space8),
  );
}
