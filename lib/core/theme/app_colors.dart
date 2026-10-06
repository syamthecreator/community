import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Core palette ──
  static const Color paletteLight = Color(0xFFF5FEFF);
  static const Color paletteSoft = Color(0xFFAAC0E1);
  static const Color paletteDeep = Color(0xFF0E2F76);

  // ── Surfaces ──
  static const Color background = paletteLight;
  static const Color kwhite = paletteLight;
  static const Color kblack = Color(0xFF000000);
  static const Color tint = Color(0xFFEAF1FB);
  static const Color homeBackground = Color(0xFFEAF1FB);

  // ── Brand ──
  static const Color brand = Color(0xFF1D4290);
  static const Color brandDark = paletteDeep;
  static const Color brandLight = Color(0xFF3B66B8);
  static const Color mint = brandLight;

  // ── Text ──
  static const Color title = paletteDeep;
  static const Color inputText = paletteDeep;
  static const Color body = Color(0xFF4A5F8C);
  static const Color hint = Color(0xFF8196BD);
  static const Color slate = Color(0xFF5B6B8C);

  // ── Lines / states ──
  static const Color border = paletteSoft;
  static const Color disabled = paletteSoft;
  static const Color error = Color(0xFFD93B4A);
  static const Color orange = Color(0xFFF59E0B);

  // ── Accents ──
  static const Color info = Color(0xFF4F86D6);
  static const Color sky = paletteSoft;
  static const Color lilac = Color(0xFF7F9AD0);
  static const Color cyan = Color(0xFF8FB0E8);
  static const Color violet = Color(0xFF5B6FB5);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFE8A317);
  static const Color rose = Color(0xFFD9576B);

  // ── My message bubble gradient ──
  static const Color sosGradientStart = brandLight;
  static const Color sosGradientEnd = brandDark;

  // ── SOS button ──
  static const Color sosRed = Color(0xFFFF4D4F);
  static const Color sosDarkRed = Color(0xFFD32030);
  static const Color sosDeepRed = Color(0xFF8E0F1C);

  // ── Skeleton loader ──
  static const Color skeletonBase = Color(0xFFD3DFF1);
  static const Color skeletonHighlight = Color(0xFFF2F7FF);

  // ── Effects ──
  static const Color glassShadow = paletteDeep;
}
