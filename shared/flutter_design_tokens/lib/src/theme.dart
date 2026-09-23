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
  // Declared slot by slot rather than seeded. `ColorScheme.fromSeed` derives
  // a full Material 3 tonal palette from one colour and only the slots named
  // here would have been ours — every other slot (surfaceContainer*,
  // onSurfaceVariant, outline, the *Container pairs, surfaceTint) came back
  // as machine-mixed blue-mauve that no brand token defines. Those slots are
  // not decorative: Material paints text-field fills, cursors, disabled
  // states, chips and dialogs from them, so the palette leaked into the UI
  // as colours that belong to no theme — most visibly in dark mode.
  //
  // Only navy, teal and gold appear here, plus green and red carrying their
  // conventional meanings of healthy and wrong.
  final colorScheme = ColorScheme(
    brightness: brightness,

    // The primary action's colour — navy in light, gold in dark. Material
    // paints a great deal from `primary` (buttons, progress, selection
    // controls, indicators), which is exactly why this is the CTA role and
    // not the structural navy: setting it here is what carries the gold
    // treatment across the app without a single screen naming a colour.
    primary: palette.actionCta,
    onPrimary: palette.onActionCta,
    primaryContainer: palette.surfaceNavyTint,
    onPrimaryContainer: palette.textHeading,

    // Teal — the accent: links, selection, active states.
    secondary: palette.actionAccent,
    onSecondary: palette.textInverse,
    secondaryContainer: palette.surfaceTealTint,
    onSecondaryContainer: palette.textAccent,

    // Gold — ceremonial only, never a large fill.
    tertiary: palette.actionGold,
    onTertiary: HHColors.navy900,
    tertiaryContainer: palette.surfaceGoldTint,
    onTertiaryContainer: palette.textGold,

    // Red means wrong. Green has no ColorScheme slot of its own, so health
    // is expressed through `HHPalette.success*` where it is needed.
    error: palette.danger500,
    onError: palette.textInverse,
    errorContainer: palette.danger100,
    onErrorContainer: palette.danger700,

    surface: palette.surfaceCard,
    onSurface: palette.textBody,
    onSurfaceVariant: palette.textMuted,

    // The elevation ramp Material reaches for on sheets, menus and fields.
    surfaceContainerLowest: palette.surfacePage,
    surfaceContainerLow: palette.surfaceSunken,
    surfaceContainer: palette.surfaceCard,
    surfaceContainerHigh: palette.surfaceRaised,
    surfaceContainerHighest: palette.surfaceRaised,

    outline: palette.borderDefault,
    outlineVariant: palette.borderSubtle,

    inverseSurface: palette.surfaceNavyDeep,
    onInverseSurface: palette.textOnNavy,
    inversePrimary: palette.actionAccent,

    shadow: HHColors.navy900,
    scrim: palette.surfaceOverlay,

    // Material tints elevated surfaces with this by default, which is what
    // made cards and sheets drift off-palette as they rose. The elevation
    // ramp above carries that job instead.
    surfaceTint: Colors.transparent,
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
    // Selection is an active state, which is teal's job in this system —
    // otherwise the cursor and handles inherit primary and a text field
    // reads as navy-on-navy while being edited.
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.actionAccent,
      selectionColor: palette.surfaceAccentTint,
      selectionHandleColor: palette.actionAccent,
    ),
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
    // A FAB is a primary action, so it takes the CTA role — navy on a light
    // page, gold on a dark one — never Material's auto-derived tonal
    // `secondaryContainer`, which is a colour no brand token defines.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.actionCta,
      foregroundColor: palette.onActionCta,
      extendedTextStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, fontWeight: HHTypeScale.weightMedium),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.actionCta,
        foregroundColor: palette.onActionCta,
        disabledBackgroundColor: palette.actionDisabledBg,
        disabledForegroundColor: palette.actionDisabledText,
        minimumSize: const Size.fromHeight(HHSpacing.controlHMd),
        padding: const EdgeInsets.symmetric(horizontal: HHSpacing.controlPadX),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.control)),
        textStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, fontWeight: HHTypeScale.weightMedium),
      ),
    ),
    // `FilledButton` is what the bespoke CTAs use (Book Hall, the dialog
    // confirms). It already took `primary`/`onPrimary`, so the CTA role
    // reaches it for free — this only brings its shape and type into line
    // with the other buttons.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.actionCta,
        foregroundColor: palette.onActionCta,
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
        foregroundColor: palette.actionCta,
        side: BorderSide(color: palette.borderDefault),
        minimumSize: const Size.fromHeight(HHSpacing.controlHMd),
        padding: const EdgeInsets.symmetric(horizontal: HHSpacing.controlPadX),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.control)),
        textStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, fontWeight: HHTypeScale.weightMedium),
      ),
    ),
    // A text button is a link, and links are teal in this system. Left to
    // Material it takes `primary` — navy — which in dark mode is navy text
    // on a navy card ("Forgot password?" was all but invisible there).
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.textLink,
        textStyle: GoogleFonts.jost(fontSize: HHTypeScale.textSm, fontWeight: HHTypeScale.weightMedium),
      ),
    ),
    // Gold box, white tick — as drawn in the approved login design. Left to
    // Material the box takes `primary`, and navy on a navy surface reads as
    // nothing at all.
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.actionGold : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(palette.textInverse),
      side: BorderSide(color: palette.borderDefault, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.sm)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceField,
      // The leading icon is the field's brand mark; the trailing one is a
      // control (show/hide password) and stays quiet.
      prefixIconColor: palette.actionGold,
      suffixIconColor: palette.textMuted,
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
    // Everything below was previously left to Material's defaults, which
    // derive from the tonal palette rather than from any brand token — the
    // route by which off-palette colour kept reappearing in dark mode.
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.actionCta,
      linearTrackColor: palette.surfaceSunken,
      circularTrackColor: palette.surfaceSunken,
    ),
    // Dialogs and sheets are raised surfaces; without this they inherit a
    // tinted `surfaceContainerHigh` and drift off-palette as they elevate.
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.modal)),
      titleTextStyle: HHTypography.serifMd.copyWith(color: palette.textHeading),
      contentTextStyle: HHTypography.textMd.copyWith(color: palette.textBody),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalBackgroundColor: palette.surfaceRaised,
      modalElevation: 0,
      dragHandleColor: palette.borderStrong,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HHRadii.xl2)),
      ),
    ),
    // A snackbar is deliberately the inverse of the page in both themes, so
    // it reads as an overlay rather than as another card.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceNavyDeep,
      contentTextStyle: HHTypography.textSm.copyWith(color: palette.textOnNavy),
      actionTextColor: palette.textGold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.control)),
    ),
    // Filter chips: selected takes the accent wash and the accent's own
    // text, rather than Material's `secondaryContainer` lavender.
    chipTheme: ChipThemeData(
      backgroundColor: palette.surfaceField,
      selectedColor: palette.surfaceAccentTint,
      disabledColor: palette.actionDisabledBg,
      checkmarkColor: palette.textAccent,
      labelStyle: HHTypography.textSm.copyWith(color: palette.textBody),
      secondaryLabelStyle: HHTypography.textSm.copyWith(color: palette.textAccent),
      side: BorderSide(color: palette.borderDefault),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HHRadii.control)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: palette.textAccent,
      unselectedLabelColor: palette.textMuted,
      indicatorColor: palette.actionCta,
      dividerColor: palette.borderSubtle,
      labelStyle: HHTypography.textSm.copyWith(fontWeight: HHTypeScale.weightMedium),
      unselectedLabelStyle: HHTypography.textSm,
    ),
    // Selection controls follow the CTA role, so a checked switch or radio
    // is gold in dark for the same reason a primary button is.
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.onActionCta : palette.textSubtle,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.actionCta : palette.surfaceSunken,
      ),
      trackOutlineColor: WidgetStatePropertyAll(palette.borderDefault),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.actionCta : palette.borderStrong,
      ),
    ),
    iconTheme: IconThemeData(color: palette.textBody),
    listTileTheme: ListTileThemeData(
      iconColor: palette.textMuted,
      textColor: palette.textBody,
      titleTextStyle: HHTypography.textMd.copyWith(color: palette.textHeading),
      subtitleTextStyle: HHTypography.textSm.copyWith(color: palette.textMuted),
    ),
  );
}
