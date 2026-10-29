import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours sampled from unihive.shop (computed styles).
class UH {
  // Dark (default) palette
  static const bg = Color(0xFF040B08); // page background
  static const surface = Color(0xFF06130D); // nav bar / header
  static const card = Color(0xFF0A1A12); // cards & panels
  static const cardHi = Color(0xFF10261A); // raised / selected
  static const gold = Color(0xFFE7C65F); // brand accent (buttons, prices, logo)
  static const onGold = Color(0xFF113B1E); // text on gold buttons
  static const text = Color(0xFFFAFAFA);
  static const muted = Color(0xFF9AA59F);
  static const border = Color(0x26E7C65F); // gold @ 15%
  static const success = Color(0xFF16A34A); // checkout button
  static const danger = Color(0xFFEF4444);
  static const link = Color(0xFF60A5FA); // "View Seller"

  // The Buzz palette (events side)
  static const buzzRed = Color(0xFF7A0A12);
  static const buzzPurple = Color(0xFF3B0A45);
  static const buzzOrange = Color(0xFFF97316);

  // Light palette
  static const lBg = Color(0xFFFBF8EF);
  static const lCard = Color(0xFFFFFFFF);
  static const lText = Color(0xFF0B1A12);
  static const lMuted = Color(0xFF5B6660);
}

/// Headings on the site are serif (Georgia / Playfair), body is Open Sans,
/// and The Buzz uses a wide display face.
TextStyle serif(double size, {Color? color, FontWeight w = FontWeight.w700}) =>
    GoogleFonts.playfairDisplay(fontSize: size, fontWeight: w, color: color, height: 1.1);

TextStyle display(double size, {Color? color}) =>
    GoogleFonts.unbounded(fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1.05);

TextStyle eyebrow({Color color = UH.gold}) =>
    GoogleFonts.openSans(fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600, color: color);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final bg = dark ? UH.bg : UH.lBg;
  final card = dark ? UH.card : UH.lCard;
  final text = dark ? UH.text : UH.lText;
  final muted = dark ? UH.muted : UH.lMuted;

  final base = ThemeData(
    useMaterial3: true,
    brightness: b,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: b,
      primary: UH.gold,
      onPrimary: UH.onGold,
      secondary: UH.onGold,
      onSecondary: UH.gold,
      error: UH.danger,
      onError: Colors.white,
      surface: card,
      onSurface: text,
      surfaceContainerHighest: dark ? UH.cardHi : const Color(0xFFF1EBD8),
      outline: dark ? UH.border : const Color(0x33113B1E),
      onSurfaceVariant: muted,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.openSansTextTheme(base.textTheme).apply(bodyColor: text, displayColor: text),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? UH.surface : UH.lBg,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    dividerColor: dark ? UH.border : const Color(0x22113B1E),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: UH.gold,
        foregroundColor: UH.onGold,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.openSans(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: dark ? UH.gold : UH.onGold,
        side: BorderSide(color: dark ? UH.gold : UH.onGold),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.openSans(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? UH.surface : Colors.white,
      hintStyle: TextStyle(color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: dark ? UH.border : const Color(0x33113B1E))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: dark ? UH.border : const Color(0x33113B1E))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: UH.gold)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? UH.surface : Colors.white,
      indicatorColor: UH.gold.withOpacity(dark ? 0.18 : 0.35),
      labelTextStyle: WidgetStatePropertyAll(GoogleFonts.openSans(fontSize: 11, fontWeight: FontWeight.w600)),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? (dark ? UH.gold : UH.onGold) : muted,
          )),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: UH.gold,
      contentTextStyle: TextStyle(color: UH.onGold, fontWeight: FontWeight.w600),
    ),
  );
}
