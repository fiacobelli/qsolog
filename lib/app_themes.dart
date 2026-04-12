// lib/app_themes.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Available theme IDs
const kThemeDefault   = 'default';
const kThemeDark      = 'dark';
const kThemeEarth     = 'earth';
const kThemeInclusive = 'inclusive';

class AppThemes {
  static ThemeData get(String id) {
    switch (id) {
      case kThemeDark:      return _dark();
      case kThemeEarth:     return _earth();
      case kThemeInclusive: return _inclusive();
      default:              return _defaultTheme();
    }
  }

  // ── Default ── forest green, Nunito
  static ThemeData _defaultTheme() {
    const seed = Color(0xFF1B5E20);
    final cs = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: GoogleFonts.nunitoTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.nunito(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }

  // ── Dark Mode ── deep charcoal, amber accents, Source Code Pro
  static ThemeData _dark() {
    const seed = Color(0xFFFFB300); // amber
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1A1A1A),
      onSurface: Colors.white,
      primary: const Color(0xFFFFB300),
      onPrimary: Colors.black,
      secondary: const Color(0xFFFF8F00),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: GoogleFonts.sourceCodeProTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: const Color(0xFFFFB300),
        titleTextStyle: GoogleFonts.sourceCodePro(
            color: const Color(0xFFFFB300), fontSize: 18, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB300), foregroundColor: Colors.black),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF242424),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFB300), width: 2)),
      ),
    );
  }

  // ── Earth ── warm terracotta and sand tones, Merriweather
  static ThemeData _earth() {
    const seed = Color(0xFF8B4513); // saddle brown
    const appBar = Color(0xFF6D3410);
    const button = Color(0xFFA0522D);
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: seed,
      secondary: const Color(0xFFD2691E),
      tertiary: const Color(0xFF8FBC8F),
      surface: const Color(0xFFFDF5E6), // old lace
      onSurface: const Color(0xFF3E1F00),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFFDF5E6),
      textTheme: GoogleFonts.merriweatherTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: const Color(0xFFFFF8DC), // cornsilk
        titleTextStyle: GoogleFonts.merriweather(
            color: const Color(0xFFFFF8DC), fontSize: 18, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: button, foregroundColor: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFAF0DC),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEDD9B0),
        labelStyle: const TextStyle(color: Color(0xFF3E1F00)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF8B4513), width: 2)),
        fillColor: Color(0xFFFFF8F0),
        filled: true,
      ),
    );
  }

  // ── Inclusive ── high contrast, bold, dyslexia-friendly OpenDyslexic/Atkinson
  static ThemeData _inclusive() {
    const seed = Color(0xFF0057B7); // strong blue
    const onDark = Colors.white;
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: seed,
      onPrimary: onDark,
      secondary: const Color(0xFFFF6600),   // high contrast orange
      onSecondary: onDark,
      tertiary: const Color(0xFF007700),
      surface: Colors.white,
      onSurface: Colors.black,
      error: const Color(0xFFCC0000),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: Colors.white,
      // Atkinson Hyperlegible is designed for low-vision readers
      textTheme: GoogleFonts.atkinsonHyperlegibleTextTheme().apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: seed,
        foregroundColor: onDark,
        titleTextStyle: GoogleFonts.atkinsonHyperlegible(
            color: onDark, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: onDark,
          minimumSize: const Size(0, 48), // larger tap targets
          textStyle: GoogleFonts.atkinsonHyperlegible(
              fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: Color(0xFF0057B7), width: 2),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderSide: BorderSide(width: 2)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0057B7), width: 3)),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Color(0xFFCCCCCC))),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Color(0xFF0057B7))),
      ),
    );
  }
}

/// Human-readable label for each theme ID
const Map<String, String> kThemeLabels = {
  kThemeDefault:   'Default (Green)',
  kThemeDark:      'Dark Mode',
  kThemeEarth:     'Earth',
  kThemeInclusive: 'Inclusive',
};

/// Icon for each theme ID
const Map<String, IconData> kThemeIcons = {
  kThemeDefault:   Icons.eco,
  kThemeDark:      Icons.dark_mode,
  kThemeEarth:     Icons.terrain,
  kThemeInclusive: Icons.accessibility_new,
};
