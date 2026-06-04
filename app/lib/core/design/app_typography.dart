import 'package:flutter/material.dart';

/// App typography.
///
/// Brand display/headings use **Plus Jakarta Sans** (a modern geometric
/// grotesque, Airbnb-Cereal-like); body/UI text uses **Inter**. Both families
/// are bundled under `assets/fonts/` (declared in pubspec.yaml) so the
/// offline-first app never has to fetch fonts at runtime.
class AppTypography {
  AppTypography._();

  static const String displayFamily = 'PlusJakartaSans';
  static const String bodyFamily = 'Inter';

  /// Build the full [TextTheme] for the given [color] (text-primary of the mode).
  /// Secondary/tertiary colors are applied per-widget where needed.
  static TextTheme textTheme(Color color) {
    return TextTheme(
      // Display / headlines — brand font.
      displayLarge: TextStyle(
        fontFamily: displayFamily,
        color: color,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontFamily: displayFamily,
        color: color,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      displaySmall: TextStyle(
        fontFamily: displayFamily,
        color: color,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFamily,
        color: color,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontFamily: displayFamily,
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontFamily: displayFamily,
        color: color,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      // Titles / labels / body — UI font.
      titleMedium: TextStyle(
        fontFamily: bodyFamily,
        color: color,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleSmall: TextStyle(
        fontFamily: bodyFamily,
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFamily,
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFamily,
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFamily,
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        fontFamily: bodyFamily,
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFamily,
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFamily,
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
