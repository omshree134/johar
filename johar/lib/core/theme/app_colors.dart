import 'package:flutter/material.dart';

/// Palette. Three layers, each with one job:
///  1. Brand: manganese + mineral neutrals (surfaces, text, headers).
///  2. Sohrai accents: red ochre and kaolin white, the pigments of
///     Jharkhand's Sohrai/Khovar wall art (which also uses manganese).
///     DECORATIVE ONLY: patterns and illustrations, never states.
///  3. ISO 7010 safety colours: only ever used for their meaning.
///     Green = safe/correct, red = danger/wrong, yellow = warning, blue = mandatory.
abstract final class AppColors {
  // Brand
  static const manganese = Color(0xFF33294F);
  static const manganeseDeep = Color(0xFF221A38);
  static const manganeseSoft = Color(0xFFE7E3F1);

  // Sohrai accents (decorative)
  static const ochre = Color(0xFFB0532A);
  static const ochreSoft = Color(0xFFF3E1D6);
  static const kaolin = Color(0xFFF8F5F0);

  // Neutrals
  static const mineral = Color(0xFFEEF1F0);
  static const surface = Color(0xFFFFFFFF);
  static const coal = Color(0xFF1E2226);
  static const slate = Color(0xFF5A6169);
  static const line = Color(0xFFD5DAD8);

  // ISO 7010 safety colours (meaning-bound)
  static const fireRed = Color(0xFFC4201F);
  static const warningYellow = Color(0xFFF4B400);
  static const mandatoryBlue = Color(0xFF0B5CAD);
  static const safeGreen = Color(0xFF17784A);

  static const safeGreenSoft = Color(0xFFE2F1E8);
  static const fireRedSoft = Color(0xFFF8E3E2);
  static const warningSoft = Color(0xFFFFF4D6);
  static const mandatorySoft = Color(0xFFE1ECF8);
}

/// Corner radii. Bigger radius = bigger, friendlier surface.
abstract final class AppRadii {
  static const sm = 12.0; // chips, small pills
  static const md = 18.0; // buttons, inputs
  static const lg = 24.0; // cards, tiles
  static const xl = 32.0; // sheets, headers
}

/// Soft, layered shadow used for floating cards.
const List<BoxShadow> kCardShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
  BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
];
