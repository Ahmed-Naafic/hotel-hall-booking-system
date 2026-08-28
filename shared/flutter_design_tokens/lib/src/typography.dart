import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Font-family and raw type-scale tokens, ported from
/// `Hotel Hall Design System/tokens/typography.css` and
/// `Hotel Hall Design System/tokens/fonts.css` (FE-00).
///
/// **Font substitution, per `fonts.css`'s own `SUBSTITUTION NOTICE`:** no
/// font binaries were supplied with the brand assets, so the CSS file
/// already names the nearest Google Fonts matches (Cinzel, Cormorant
/// Garamond, Jost) — this package ports that decision verbatim via the
/// `google_fonts` package, the implementation-time technology choice
/// Module 1's Technical Design §18.2 left open. Replace with licensed
/// binaries here, in one place, if they become available later — every
/// consumer of this package picks the change up automatically.
///
/// CSS `clamp(min, viewport, max)` display sizes (`--display-xl`,
/// `--display-lg`) have no direct mobile-app equivalent — a representative
/// fixed size (the clamp's midpoint) is used instead, documented at each
/// constant below, not silently invented.
abstract final class HHTypeScale {
  // --- Display: the titling serif, ALWAYS uppercase, generous tracking ---
  /// CSS `clamp(44px, 5.6vw, 76px)` — representative fixed midpoint.
  static const double displayXl = 56;

  /// CSS `clamp(34px, 4vw, 54px)` — representative fixed midpoint.
  static const double displayLg = 40;

  static const double displayMd = 30;
  static const double displaySm = 22;
  static const double displayTracking = 0.06; // em
  static const double displayTrackingWide = 0.14; // em
  static const double displayLeading = 1.08;
  static const FontWeight displayWeight = FontWeight.w600;

  // --- Editorial serif: subheads, pull quotes, room descriptions ---
  static const double serifLg = 30;
  static const double serifMd = 22;
  static const double serifSm = 18;
  static const double serifLeading = 1.45;

  // --- UI sans scale ---
  static const double text2xs = 11;
  static const double textXs = 12;
  static const double textSm = 13;
  static const double textMd = 15;
  static const double textLg = 17;
  static const double textXl = 20;
  static const double text2xl = 24;
  static const double leadingTight = 1.2;
  static const double leadingSnug = 1.35;
  static const double leadingNormal = 1.55;
  static const double leadingLoose = 1.7;
  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;

  // --- Eyebrow / overline: the "BOOK • STAY • CELEBRATE" treatment ---
  static const double eyebrowSize = 12;
  static const double eyebrowTracking = 0.22; // em
  static const FontWeight eyebrowWeight = FontWeight.w500;

  static const double trackingTight = -0.01; // em
  static const double trackingNormal = 0; // em
  static const double trackingWide = 0.04; // em
  static const double trackingWider = 0.1; // em
  static const double trackingWidest = 0.22; // em
}

/// CSS `em` letter-spacing is relative to font size; Flutter's
/// `TextStyle.letterSpacing` is absolute logical pixels. This converts one
/// to the other, the same way a browser resolves `letter-spacing: 0.04em`
/// against the element's own `font-size`.
double emToPx(double em, double fontSizePx) => em * fontSizePx;

/// TextStyle builders, ported from
/// `Hotel Hall Design System/tokens/typography.css`'s semantic type
/// aliases (`--type-page-title`, `--type-section-title`, `--type-card-title`,
/// `--type-body`, `--type-caption`) plus the raw scale above. Font family
/// per `HHTypeScale`'s substitution notice.
abstract final class HHTypography {
  static TextStyle _display({required double size, double tracking = HHTypeScale.displayTracking}) =>
      GoogleFonts.cinzel(
        fontSize: size,
        fontWeight: HHTypeScale.displayWeight,
        letterSpacing: emToPx(tracking, size),
        height: HHTypeScale.displayLeading,
        color: HHColors.textHeading,
      );

  static TextStyle _serif({required double size}) => GoogleFonts.cormorantGaramond(
        fontSize: size,
        height: HHTypeScale.serifLeading,
        color: HHColors.textHeading,
      );

  static TextStyle _sans({
    required double size,
    required FontWeight weight,
    double tracking = HHTypeScale.trackingNormal,
    double height = HHTypeScale.leadingNormal,
    Color? color,
  }) =>
      GoogleFonts.jost(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: emToPx(tracking, size),
        height: height,
        color: color ?? HHColors.textBody,
      );

  // Display (h1-equivalent and up) — always uppercase in usage, per
  // `Hotel Hall Design System/tokens/base.css`'s `h1,h2,h3,h4` rule;
  // callers apply `.toUpperCase()` themselves (this package styles text,
  // it does not transform it).
  static TextStyle get displayXl => _display(size: HHTypeScale.displayXl, tracking: HHTypeScale.displayTrackingWide);
  static TextStyle get displayLg => _display(size: HHTypeScale.displayLg);
  static TextStyle get displayMd => _display(size: HHTypeScale.displayMd);
  static TextStyle get displaySm => _display(size: HHTypeScale.displaySm);

  static TextStyle get serifLg => _serif(size: HHTypeScale.serifLg);
  static TextStyle get serifMd => _serif(size: HHTypeScale.serifMd);
  static TextStyle get serifSm => _serif(size: HHTypeScale.serifSm);

  static TextStyle get text2xs => _sans(size: HHTypeScale.text2xs, weight: HHTypeScale.weightRegular);
  static TextStyle get textXs => _sans(size: HHTypeScale.textXs, weight: HHTypeScale.weightRegular);
  static TextStyle get textSm => _sans(size: HHTypeScale.textSm, weight: HHTypeScale.weightRegular);
  static TextStyle get textMd => _sans(size: HHTypeScale.textMd, weight: HHTypeScale.weightRegular);
  static TextStyle get textLg => _sans(size: HHTypeScale.textLg, weight: HHTypeScale.weightRegular);
  static TextStyle get textXl => _sans(size: HHTypeScale.textXl, weight: HHTypeScale.weightMedium);
  static TextStyle get text2xl => _sans(size: HHTypeScale.text2xl, weight: HHTypeScale.weightMedium);

  /// `.hh-eyebrow` — the "BOOK • STAY • CELEBRATE" treatment.
  static TextStyle get eyebrow => _sans(
        size: HHTypeScale.eyebrowSize,
        weight: HHTypeScale.eyebrowWeight,
        tracking: HHTypeScale.eyebrowTracking,
        color: HHColors.textGold,
      );

  // Semantic aliases — `--type-page-title`, `--type-section-title`,
  // `--type-card-title`, `--type-body`, `--type-caption`.
  static TextStyle get pageTitle => displayLg;
  static TextStyle get sectionTitle => displayMd;
  static TextStyle get cardTitle => serifSm;
  static TextStyle get body => textMd;
  static TextStyle get caption => textXs;
}
