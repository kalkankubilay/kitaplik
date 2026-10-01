import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Stitch Obsidian & Dark Minimalist Palette ────────────────
  static const Color bg           = Color(0xFF09090B); // Root canvas (Zinc-950)
  static const Color surface1     = Color(0xFF121214); // Container & Cards
  static const Color surface2     = Color(0xFF18181B); // Elevated Cards (Zinc-900)
  static const Color surface3     = Color(0xFF242528); // Surface High / Hover
  static const Color surfaceHigh  = Color(0xFF27272A); // Zinc-800

  // ── Accents ──────────────────────────────────────────────────
  static const Color primary      = Color(0xFFFFFFFF); // High-contrast White
  static const Color primaryViolet= Color(0xFF8B5CF6); // AI Electric Violet
  static const Color primaryDeep  = Color(0xFF6D28D9); // Deep Indigo
  static const Color emerald      = Color(0xFF10B981); // Positive / Active / Goal
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color gold         = Color(0xFFF59E0B); // Amber / Stars / Streaks
  static const Color goldLight    = Color(0xFFFBBF24);
  static const Color error        = Color(0xFFEF4444); // Error / Delete

  // ── Typography & Borders ─────────────────────────────────────
  static const Color textHigh     = Color(0xFFF4F4F5); // Crisp White Headlines
  static const Color textMuted    = Color(0xFFA1A1AA); // Zinc-400 Metadata / Subtitles
  static const Color textGhost    = Color(0xFF52525B); // Zinc-600 Placeholders
  static const Color border       = Color(0xFF27272A); // Zinc-800 Outlines
  static const Color borderHairline = Color(0x1FFFFFFF); // 12% opacity subtle line
  static const Color borderAccent = Color(0x338B5CF6); // Violet border glow

  // ── Legacy Getters (Safely mapped) ───────────────────────────
  static Color get surface => surface1;
  static Color get card => surface2;
  static Color get cardLight => surface3;
  static Color get textPrimary => textHigh;
  static Color get textSecondary => textMuted;
  static Color get accent => primaryViolet;

  // ── Gradients ───────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryViolet, primaryDeep],
  );

  static const LinearGradient aiWidgetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF18181B), Color(0xFF121214)],
  );

  static LinearGradient coverGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, surface1.withValues(alpha: 0.95)],
    stops: const [0.3, 1.0],
  );

  // ── Shadows ─────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primaryViolet.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get emeraldGlow => [
    BoxShadow(
      color: emerald.withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ── ThemeData ───────────────────────────────────────────────
  static ThemeData get dark {
    final base = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: textHigh,
      displayColor: textHigh,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryViolet,
        surface: surface1,
        error: error,
        onPrimary: bg,
        onSecondary: textHigh,
        onSurface: textHigh,
      ),
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textHigh,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
        ),
        iconTheme: const IconThemeData(color: textHigh),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: bg,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: surface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 1.2),
        ),
        hintStyle: const TextStyle(color: textGhost, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface2,
        contentTextStyle: const TextStyle(color: textHigh),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
