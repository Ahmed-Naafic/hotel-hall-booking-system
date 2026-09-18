import 'package:flutter/material.dart';

import 'colors.dart';

/// Every semantic colour token, resolved for one brightness.
///
/// `HHColors` stays the raw palette — `navy700` is one fixed colour in both
/// themes. This is the layer that says what each colour is *for*, and that
/// mapping is what changes between light and dark. Widgets read it through
/// `context.hh`, so a colour follows the active theme instead of being
/// compiled in.
///
/// Mirrors `Hotel Hall Design System/tokens/colors.css` role for role —
/// update the two together.
@immutable
class HHPalette extends ThemeExtension<HHPalette> {
  const HHPalette({
    required this.textHeading,
    required this.textBody,
    required this.textMuted,
    required this.textSubtle,
    required this.textInverse,
    required this.textOnNavy,
    required this.textAccent,
    required this.textGold,
    required this.textLink,
    required this.textLinkHover,
    required this.surfacePage,
    required this.surfaceCard,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceNavy,
    required this.surfaceNavyDeep,
    required this.surfaceTeal,
    required this.surfaceGoldTint,
    required this.surfaceNavyTint,
    required this.surfaceNavyTintStrong,
    required this.surfaceTealTint,
    required this.surfaceOverlay,
    required this.surfaceGlass,
    required this.surfaceGlassDark,
    required this.borderSubtle,
    required this.borderDefault,
    required this.borderStrong,
    required this.borderNavy,
    required this.borderGold,
    required this.borderRuleGold,
    required this.focusRing,
    required this.success700,
    required this.success500,
    required this.success100,
    required this.warning700,
    required this.warning500,
    required this.warning100,
    required this.danger700,
    required this.danger500,
    required this.danger100,
    required this.info700,
    required this.info500,
    required this.info100,
    required this.actionPrimary,
    required this.actionPrimaryHover,
    required this.actionPrimaryActive,
    required this.actionAccent,
    required this.actionAccentHover,
    required this.actionAccentActive,
    required this.actionGold,
    required this.actionGoldHover,
    required this.actionGoldActive,
    required this.actionDisabledBg,
    required this.actionDisabledText,
  });

  // --- Text ---
  final Color textHeading;
  final Color textBody;
  final Color textMuted;
  final Color textSubtle;
  final Color textInverse;
  final Color textOnNavy;
  final Color textAccent;
  final Color textGold;
  final Color textLink;
  final Color textLinkHover;
  // --- Surfaces ---
  final Color surfacePage;
  final Color surfaceCard;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color surfaceNavy;
  final Color surfaceNavyDeep;
  final Color surfaceTeal;
  final Color surfaceGoldTint;
  final Color surfaceNavyTint;
  final Color surfaceNavyTintStrong;
  final Color surfaceTealTint;
  final Color surfaceOverlay;
  final Color surfaceGlass;
  final Color surfaceGlassDark;
  // --- Lines ---
  final Color borderSubtle;
  final Color borderDefault;
  final Color borderStrong;
  final Color borderNavy;
  final Color borderGold;
  final Color borderRuleGold;
  final Color focusRing;
  // --- Status ---
  final Color success700;
  final Color success500;
  final Color success100;
  final Color warning700;
  final Color warning500;
  final Color warning100;
  final Color danger700;
  final Color danger500;
  final Color danger100;
  final Color info700;
  final Color info500;
  final Color info100;
  // --- Interactive ---
  final Color actionPrimary;
  final Color actionPrimaryHover;
  final Color actionPrimaryActive;
  final Color actionAccent;
  final Color actionAccentHover;
  final Color actionAccentActive;
  final Color actionGold;
  final Color actionGoldHover;
  final Color actionGoldActive;
  final Color actionDisabledBg;
  final Color actionDisabledText;

  static const light = HHPalette(
    textHeading: HHColors.navy700,
    textBody: HHColors.gray700,
    textMuted: HHColors.gray500,
    textSubtle: HHColors.gray400,
    textInverse: HHColors.white,
    textOnNavy: HHColors.textOnNavy,
    textAccent: HHColors.teal700,
    textGold: HHColors.gold700,
    textLink: HHColors.teal700,
    textLinkHover: HHColors.navy700,
    surfacePage: HHColors.ivory,
    surfaceCard: HHColors.white,
    surfaceRaised: HHColors.white,
    surfaceSunken: HHColors.sand100,
    surfaceNavy: HHColors.navy700,
    surfaceNavyDeep: HHColors.navy900,
    surfaceTeal: HHColors.teal700,
    surfaceGoldTint: HHColors.gold100,
    surfaceNavyTint: HHColors.navy050,
    surfaceNavyTintStrong: HHColors.navy100,
    surfaceTealTint: HHColors.teal100,
    surfaceOverlay: HHColors.surfaceOverlay,
    surfaceGlass: HHColors.surfaceGlass,
    surfaceGlassDark: HHColors.surfaceGlassDark,
    borderSubtle: HHColors.gray200,
    borderDefault: HHColors.gray300,
    borderStrong: HHColors.navy200,
    borderNavy: HHColors.navy700,
    borderGold: HHColors.gold600,
    borderRuleGold: HHColors.gold500,
    focusRing: HHColors.teal600,
    success700: HHColors.success700,
    success500: HHColors.success500,
    success100: HHColors.success100,
    warning700: HHColors.warning700,
    warning500: HHColors.warning500,
    warning100: HHColors.warning100,
    danger700: HHColors.danger700,
    danger500: HHColors.danger500,
    danger100: HHColors.danger100,
    info700: HHColors.navy600,
    info500: HHColors.navy500,
    info100: HHColors.navy100,
    actionPrimary: HHColors.navy700,
    actionPrimaryHover: HHColors.navy600,
    actionPrimaryActive: HHColors.navy800,
    actionAccent: HHColors.teal700,
    actionAccentHover: HHColors.teal600,
    actionAccentActive: HHColors.teal800,
    actionGold: HHColors.gold600,
    actionGoldHover: HHColors.gold500,
    actionGoldActive: HHColors.gold700,
    actionDisabledBg: HHColors.gray100,
    actionDisabledText: HHColors.gray400,
  );

  static const dark = HHPalette(
    textHeading: HHColors.navy050,
    textBody: HHColors.gray200,
    textMuted: HHColors.gray400,
    textSubtle: HHColors.gray500,
    textInverse: HHColors.white,
    textOnNavy: HHColors.textOnNavy,
    textAccent: HHColors.teal400,
    textGold: HHColors.gold400,
    textLink: HHColors.teal400,
    textLinkHover: HHColors.teal300,
    surfacePage: HHColors.navy950,
    surfaceCard: HHColors.navy800,
    surfaceRaised: HHColors.navy700,
    surfaceSunken: HHColors.navy900,
    surfaceNavy: HHColors.navy800,
    surfaceNavyDeep: HHColors.navy950,
    surfaceTeal: HHColors.teal800,
    surfaceGoldTint: Color.fromRGBO(217, 175, 69, 0.16),
    surfaceNavyTint: Color.fromRGBO(74, 124, 171, 0.14),
    surfaceNavyTintStrong: Color.fromRGBO(74, 124, 171, 0.26),
    surfaceTealTint: Color.fromRGBO(58, 171, 182, 0.18),
    surfaceOverlay: Color.fromRGBO(3, 13, 26, 0.72),
    surfaceGlass: Color.fromRGBO(10, 33, 65, 0.72),
    surfaceGlassDark: Color.fromRGBO(3, 13, 26, 0.55),
    borderSubtle: Color.fromRGBO(255, 255, 255, 0.08),
    borderDefault: Color.fromRGBO(255, 255, 255, 0.16),
    borderStrong: HHColors.navy400,
    borderNavy: HHColors.navy400,
    borderGold: HHColors.gold600,
    borderRuleGold: HHColors.gold500,
    focusRing: HHColors.teal400,
    success700: Color(0xFF7EBB9C),
    success500: HHColors.success500,
    success100: Color.fromRGBO(47, 145, 96, 0.20),
    warning700: Color(0xFFDAAF69),
    warning500: HHColors.warning500,
    warning100: Color.fromRGBO(201, 138, 34, 0.20),
    danger700: Color(0xFFD78581),
    danger500: HHColors.danger500,
    danger100: Color.fromRGBO(191, 59, 51, 0.22),
    info700: HHColors.navy300,
    info500: HHColors.navy400,
    info100: Color.fromRGBO(74, 124, 171, 0.18),
    actionPrimary: HHColors.navy500,
    actionPrimaryHover: HHColors.navy400,
    actionPrimaryActive: HHColors.navy600,
    actionAccent: HHColors.teal600,
    actionAccentHover: HHColors.teal500,
    actionAccentActive: HHColors.teal700,
    actionGold: HHColors.gold500,
    actionGoldHover: HHColors.gold400,
    actionGoldActive: HHColors.gold600,
    actionDisabledBg: Color.fromRGBO(255, 255, 255, 0.08),
    actionDisabledText: HHColors.gray500,
  );

  /// Never partially overridden — a palette is only ever swapped whole, so
  /// there is nothing to copy field-by-field.
  @override
  HHPalette copyWith() => this;

  @override
  HHPalette lerp(ThemeExtension<HHPalette>? other, double t) {
    if (other is! HHPalette) return this;
    return HHPalette(
      textHeading: Color.lerp(textHeading, other.textHeading, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      textOnNavy: Color.lerp(textOnNavy, other.textOnNavy, t)!,
      textAccent: Color.lerp(textAccent, other.textAccent, t)!,
      textGold: Color.lerp(textGold, other.textGold, t)!,
      textLink: Color.lerp(textLink, other.textLink, t)!,
      textLinkHover: Color.lerp(textLinkHover, other.textLinkHover, t)!,
      surfacePage: Color.lerp(surfacePage, other.surfacePage, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      surfaceNavy: Color.lerp(surfaceNavy, other.surfaceNavy, t)!,
      surfaceNavyDeep: Color.lerp(surfaceNavyDeep, other.surfaceNavyDeep, t)!,
      surfaceTeal: Color.lerp(surfaceTeal, other.surfaceTeal, t)!,
      surfaceGoldTint: Color.lerp(surfaceGoldTint, other.surfaceGoldTint, t)!,
      surfaceNavyTint: Color.lerp(surfaceNavyTint, other.surfaceNavyTint, t)!,
      surfaceNavyTintStrong: Color.lerp(surfaceNavyTintStrong, other.surfaceNavyTintStrong, t)!,
      surfaceTealTint: Color.lerp(surfaceTealTint, other.surfaceTealTint, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      surfaceGlassDark: Color.lerp(surfaceGlassDark, other.surfaceGlassDark, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderNavy: Color.lerp(borderNavy, other.borderNavy, t)!,
      borderGold: Color.lerp(borderGold, other.borderGold, t)!,
      borderRuleGold: Color.lerp(borderRuleGold, other.borderRuleGold, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      success700: Color.lerp(success700, other.success700, t)!,
      success500: Color.lerp(success500, other.success500, t)!,
      success100: Color.lerp(success100, other.success100, t)!,
      warning700: Color.lerp(warning700, other.warning700, t)!,
      warning500: Color.lerp(warning500, other.warning500, t)!,
      warning100: Color.lerp(warning100, other.warning100, t)!,
      danger700: Color.lerp(danger700, other.danger700, t)!,
      danger500: Color.lerp(danger500, other.danger500, t)!,
      danger100: Color.lerp(danger100, other.danger100, t)!,
      info700: Color.lerp(info700, other.info700, t)!,
      info500: Color.lerp(info500, other.info500, t)!,
      info100: Color.lerp(info100, other.info100, t)!,
      actionPrimary: Color.lerp(actionPrimary, other.actionPrimary, t)!,
      actionPrimaryHover: Color.lerp(actionPrimaryHover, other.actionPrimaryHover, t)!,
      actionPrimaryActive: Color.lerp(actionPrimaryActive, other.actionPrimaryActive, t)!,
      actionAccent: Color.lerp(actionAccent, other.actionAccent, t)!,
      actionAccentHover: Color.lerp(actionAccentHover, other.actionAccentHover, t)!,
      actionAccentActive: Color.lerp(actionAccentActive, other.actionAccentActive, t)!,
      actionGold: Color.lerp(actionGold, other.actionGold, t)!,
      actionGoldHover: Color.lerp(actionGoldHover, other.actionGoldHover, t)!,
      actionGoldActive: Color.lerp(actionGoldActive, other.actionGoldActive, t)!,
      actionDisabledBg: Color.lerp(actionDisabledBg, other.actionDisabledBg, t)!,
      actionDisabledText: Color.lerp(actionDisabledText, other.actionDisabledText, t)!,
    );
  }
}

/// `context.hh.textMuted` — the palette for the active theme.
///
/// Falls back to the light palette when no theme registered one, so a widget
/// still renders under a bare `MaterialApp` (as many widget tests build).
extension HHPaletteContext on BuildContext {
  HHPalette get hh => Theme.of(this).extension<HHPalette>() ?? HHPalette.light;
}
