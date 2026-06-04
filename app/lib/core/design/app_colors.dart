import 'package:flutter/material.dart';

/// Semantic color palette for one brightness mode.
///
/// The app reads colors through [ColorScheme] (via the theme) wherever possible.
/// This palette holds the brand/extra semantic roles that don't map cleanly onto
/// a [ColorScheme] (veg/non-veg badges, glass tints, soft surfaces, etc.) and is
/// exposed to widgets via the [AppPaletteExtension] theme extension.
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.brand,
    required this.brandPressed,
    required this.onBrand,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.veg,
    required this.nonVeg,
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
    required this.glassTint,
    required this.glassBorder,
  });

  final Brightness brightness;

  /// Primary brand accent (coral/saffron) — CTAs, selected states.
  final Color brand;
  final Color brandPressed;
  final Color onBrand;

  /// Scaffold background (slightly off the surface for depth).
  final Color background;

  /// Default card/sheet surface.
  final Color surface;

  /// Raised surface (popovers, selected tiles).
  final Color surfaceElevated;

  /// Muted fill (input fields, chips at rest).
  final Color surfaceMuted;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color border;
  final Color divider;

  /// Veg (green) / non-veg (red) food indicators.
  final Color veg;
  final Color nonVeg;

  final Color success;
  final Color warning;
  final Color info;
  final Color danger;

  /// Tint painted behind the blur on glass surfaces (and the solid fallback).
  final Color glassTint;

  /// Hairline border on glass surfaces.
  final Color glassBorder;

  bool get isDark => brightness == Brightness.dark;

  // ---- Light palette ---------------------------------------------------------
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    brand: Color(0xFFFF5A33),
    brandPressed: Color(0xFFE64A28),
    onBrand: Color(0xFFFFFFFF),
    background: Color(0xFFFAFAF8),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF2F2EF),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6B6B70),
    textTertiary: Color(0xFF9A9AA0),
    border: Color(0xFFE7E7E3),
    divider: Color(0xFFEDEDEA),
    veg: Color(0xFF18A957),
    nonVeg: Color(0xFFE5484D),
    success: Color(0xFF18A957),
    warning: Color(0xFFE9920B),
    info: Color(0xFF2EAADC),
    danger: Color(0xFFE5484D),
    glassTint: Color(0xFFFFFFFF),
    glassBorder: Color(0x33FFFFFF),
  );

  // ---- Dark palette ----------------------------------------------------------
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    brand: Color(0xFFFF6B47),
    brandPressed: Color(0xFFFF7E5E),
    onBrand: Color(0xFFFFFFFF),
    background: Color(0xFF0F0F12),
    surface: Color(0xFF17171C),
    surfaceElevated: Color(0xFF202027),
    surfaceMuted: Color(0xFF22222A),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFFA0A0A8),
    textTertiary: Color(0xFF6E6E78),
    border: Color(0xFF2C2C34),
    divider: Color(0xFF26262D),
    veg: Color(0xFF2BD49B),
    nonVeg: Color(0xFFFF6168),
    success: Color(0xFF2BD49B),
    warning: Color(0xFFFFB23E),
    info: Color(0xFF4FC3E8),
    danger: Color(0xFFFF6168),
    glassTint: Color(0xFF1A1A20),
    glassBorder: Color(0x1FFFFFFF),
  );

  /// Build a Material 3 [ColorScheme] from this palette.
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,
      primary: brand,
      onPrimary: onBrand,
      primaryContainer: brand.withValues(alpha: isDark ? 0.22 : 0.12),
      onPrimaryContainer: isDark ? brand : brandPressed,
      secondary: info,
      onSecondary: Colors.white,
      secondaryContainer: info.withValues(alpha: isDark ? 0.22 : 0.12),
      onSecondaryContainer: info,
      tertiary: veg,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      errorContainer: danger.withValues(alpha: isDark ? 0.22 : 0.10),
      onErrorContainer: danger,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerHighest: surfaceMuted,
      surfaceContainerHigh: surfaceElevated,
      surfaceContainer: surface,
      surfaceContainerLow: background,
      surfaceContainerLowest: background,
      outline: border,
      outlineVariant: divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? textPrimary : const Color(0xFF2A2A2E),
      onInverseSurface: isDark ? background : Colors.white,
      inversePrimary: brand,
    );
  }
}

/// Exposes [AppPalette] through the theme so widgets can read brand/glass colors
/// via `Theme.of(context).extension<AppPaletteExtension>()` (or the
/// `context.palette` getter in app_theme.dart).
@immutable
class AppPaletteExtension extends ThemeExtension<AppPaletteExtension> {
  const AppPaletteExtension(this.palette);

  final AppPalette palette;

  @override
  AppPaletteExtension copyWith({AppPalette? palette}) =>
      AppPaletteExtension(palette ?? this.palette);

  @override
  AppPaletteExtension lerp(ThemeExtension<AppPaletteExtension>? other, double t) {
    // Palette swaps wholesale between light/dark; no per-channel lerp needed.
    if (other is! AppPaletteExtension) return this;
    return t < 0.5 ? this : other;
  }
}
