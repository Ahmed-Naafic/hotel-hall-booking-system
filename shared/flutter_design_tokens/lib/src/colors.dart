import 'package:flutter/widgets.dart';

/// Color tokens, ported 1:1 from
/// `Hotel Hall Design System/tokens/colors.css` (FE-00). Values are not
/// re-derived or approximated — every hex code here matches the CSS
/// custom property of the same name exactly. Update this file only when
/// the source `.css` token file changes.
abstract final class HHColors {
  // --- Brand scales ---
  static const navy900 = Color(0xFF06182F);
  static const navy800 = Color(0xFF0A2141);
  static const navy700 = Color(0xFF0C2A4E);
  static const navy600 = Color(0xFF123F6D);
  static const navy500 = Color(0xFF1D558C);
  static const navy400 = Color(0xFF4A7CAB);
  static const navy300 = Color(0xFF8DAAC6);
  static const navy200 = Color(0xFFC3D3E2);
  static const navy100 = Color(0xFFE4EBF2);
  static const navy050 = Color(0xFFF3F6FA);

  static const teal900 = Color(0xFF0A3A41);
  static const teal800 = Color(0xFF115C65);
  static const teal700 = Color(0xFF187884);
  static const teal600 = Color(0xFF22929E);
  static const teal500 = Color(0xFF3AABB6);
  static const teal400 = Color(0xFF6EC4CC);
  static const teal300 = Color(0xFFA3DBE0);
  static const teal200 = Color(0xFFCDEBEE);
  static const teal100 = Color(0xFFE7F5F6);

  static const gold900 = Color(0xFF6B5210);
  static const gold800 = Color(0xFF9B761A);
  static const gold700 = Color(0xFFB88C1F);
  static const gold600 = Color(0xFFCC9C24);
  static const gold500 = Color(0xFFD9AF45);
  static const gold400 = Color(0xFFE5C778);
  static const gold300 = Color(0xFFEFDCAA);
  static const gold200 = Color(0xFFF7ECD2);
  static const gold100 = Color(0xFFFCF7EC);

  // --- Neutrals: warm-cool ivory through slate ---
  static const ivory = Color(0xFFFBFAF7);
  static const sand100 = Color(0xFFF5F2EC);
  static const sand200 = Color(0xFFE9E4D9);

  static const gray050 = Color(0xFFF7F8F9);
  static const gray100 = Color(0xFFEEF0F3);
  static const gray200 = Color(0xFFDFE3E8);
  static const gray300 = Color(0xFFC4CAD2);
  static const gray400 = Color(0xFF98A1AC);
  static const gray500 = Color(0xFF6C7783);
  static const gray600 = Color(0xFF4D5865);
  static const gray700 = Color(0xFF333C47);
  static const gray800 = Color(0xFF1E242C);
  static const white = Color(0xFFFFFFFF);

  // --- Semantic status ---
  static const success700 = Color(0xFF1C6B45);
  static const success500 = Color(0xFF2F9160);
  static const success100 = Color(0xFFE4F2EA);
  static const warning700 = Color(0xFF8A5A13);
  static const warning500 = Color(0xFFC98A22);
  static const warning100 = Color(0xFFFBF0DA);
  static const danger700 = Color(0xFF8F2320);
  static const danger500 = Color(0xFFBF3B33);
  static const danger100 = Color(0xFFFAE8E6);
  static const info700 = navy600;
  static const info500 = navy500;
  static const info100 = navy100;

  // --- Semantic aliases: text ---
  static const textHeading = navy700;
  static const textBody = gray700;
  static const textMuted = gray500;
  static const textSubtle = gray400;
  static const textInverse = white;
  static const textOnNavy = Color(0xFFE8EFF6);
  static const textAccent = teal700;
  static const textGold = gold700;
  static const textLink = teal700;
  static const textLinkHover = navy700;

  // --- Semantic aliases: surfaces ---
  static const surfacePage = ivory;
  static const surfaceCard = white;
  static const surfaceRaised = white;
  static const surfaceSunken = sand100;
  static const surfaceNavy = navy700;
  static const surfaceNavyDeep = navy900;
  static const surfaceTeal = teal700;
  static const surfaceGoldTint = gold100;
  static const surfaceNavyTint = navy050;
  static const surfaceOverlay = Color.fromRGBO(6, 24, 47, 0.62);
  static const surfaceGlass = Color.fromRGBO(255, 255, 255, 0.78);
  static const surfaceGlassDark = Color.fromRGBO(6, 24, 47, 0.42);

  // --- Semantic aliases: lines ---
  static const borderSubtle = gray200;
  static const borderDefault = gray300;
  static const borderStrong = navy200;
  static const borderNavy = navy700;
  static const borderGold = gold600;
  static const borderRuleGold = gold500;
  static const focusRing = teal600;

  // --- Interactive ---
  static const actionPrimary = navy700;
  static const actionPrimaryHover = navy600;
  static const actionPrimaryActive = navy800;
  static const actionAccent = teal700;
  static const actionAccentHover = teal600;
  static const actionAccentActive = teal800;
  static const actionGold = gold600;
  static const actionGoldHover = gold500;
  static const actionGoldActive = gold700;
  static const actionDisabledBg = gray100;
  static const actionDisabledText = gray400;
}
