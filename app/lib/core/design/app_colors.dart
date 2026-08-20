import 'package:flutter/material.dart';

import 'app_accent.dart';

/// Semantic color palette for one brightness mode and accent color.
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
    required this.headerGradient,
    required this.heroBannerGradient,
    required this.heroHeartColor,
    required this.cardGlowGradient,
  });

  final Brightness brightness;

  /// Primary brand accent — CTAs, selected states.
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

  /// Dynamic top header gradient (for Home & Drinks tabs).
  final List<Color> headerGradient;

  /// Dynamic hero banner gradient (flows continuously from the bottom of headerGradient).
  final List<Color> heroBannerGradient;

  /// Dynamic heart accent color in the "Grab a Bite" hero banner logo.
  final Color heroHeartColor;

  /// Dynamic soft light glow for food & drink card containers.
  final List<Color> cardGlowGradient;

  bool get isDark => brightness == Brightness.dark;

  /// Factory creating an [AppPalette] dynamically from brightness and user's chosen [AppAccent].
  static AppPalette create({
    required Brightness brightness,
    required AppAccent accent,
  }) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return AppPalette(
        brightness: Brightness.dark,
        brand: accent.darkBrand,
        brandPressed: accent.darkBrandPressed,
        onBrand: const Color(0xFFFFFFFF),
        background: const Color(0xFF09090D),
        surface: const Color(0xFF16161D),
        surfaceElevated: const Color(0xFF1F1F28),
        surfaceMuted: const Color(0xFF262632),
        textPrimary: const Color(0xFFF5F5F7),
        textSecondary: const Color(0xFFA0A0A8),
        textTertiary: const Color(0xFF6E6E78),
        border: const Color(0xFF2E2E3C),
        divider: const Color(0xFF242430),
        veg: const Color(0xFF108A65),
        nonVeg: const Color(0xFFE43B4F),
        success: const Color(0xFF108A65),
        warning: const Color(0xFFFFB23E),
        info: accent.darkBrand,
        danger: const Color(0xFFE43B4F),
        glassTint: const Color(0xFF1A1A22),
        glassBorder: const Color(0x24FFFFFF),
        headerGradient: accent.darkHeaderGradient,
        heroBannerGradient: accent.darkHeroBannerGradient,
        heroHeartColor: accent.heroHeartColor,
        cardGlowGradient: accent.darkCardGlow,
      );
    } else {
      return AppPalette(
        brightness: Brightness.light,
        brand: accent.lightBrand,
        brandPressed: accent.lightBrandPressed,
        onBrand: const Color(0xFFFFFFFF),
        background: const Color(0xFFFAFAF8),
        surface: const Color(0xFFFFFFFF),
        surfaceElevated: const Color(0xFFFFFFFF),
        surfaceMuted: const Color(0xFFF2F2EF),
        textPrimary: const Color(0xFF1C1C1E),
        textSecondary: const Color(0xFF6B6B70),
        textTertiary: const Color(0xFF9A9AA0),
        border: const Color(0xFFE7E7E3),
        divider: const Color(0xFFEDEDEA),
        veg: const Color(0xFF108A65),
        nonVeg: const Color(0xFFE43B4F),
        success: const Color(0xFF108A65),
        warning: const Color(0xFFE9920B),
        info: accent.lightBrand,
        danger: const Color(0xFFE43B4F),
        glassTint: const Color(0xFFFFFFFF),
        glassBorder: const Color(0x33FFFFFF),
        headerGradient: accent.lightHeaderGradient,
        heroBannerGradient: accent.lightHeroBannerGradient,
        heroHeartColor: accent.heroHeartColor,
        cardGlowGradient: accent.lightCardGlow,
      );
    }
  }

  // ---- Default Fallback Palettes (Sapphire) -----------------------------------
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    brand: Color(0xFF0072E5),
    brandPressed: Color(0xFF005BC4),
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
    veg: Color(0xFF108A65),
    nonVeg: Color(0xFFE43B4F),
    success: Color(0xFF108A65),
    warning: Color(0xFFE9920B),
    info: Color(0xFF0072E5),
    danger: Color(0xFFE43B4F),
    glassTint: Color(0xFFFFFFFF),
    glassBorder: Color(0x33FFFFFF),
    headerGradient: [Color(0xFF00BBFF), Color(0xFF0078FF)],
    heroBannerGradient: [Color(0xFF0078FF), Color(0xFF0048FF)],
    heroHeartColor: Color(0xFF36FFEB),
    cardGlowGradient: [Color(0xFFE2EFFF), Color(0xFFF5F9FD), Colors.white],
  );

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    brand: Color(0xFF2997FF),
    brandPressed: Color(0xFF0072E5),
    onBrand: Color(0xFFFFFFFF),
    background: Color(0xFF09090D),
    surface: Color(0xFF16161D),
    surfaceElevated: Color(0xFF1F1F28),
    surfaceMuted: Color(0xFF262632),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFFA0A0A8),
    textTertiary: Color(0xFF6E6E78),
    border: Color(0xFF2E2E3C),
    divider: Color(0xFF242430),
    veg: Color(0xFF108A65),
    nonVeg: Color(0xFFE43B4F),
    success: Color(0xFF108A65),
    warning: Color(0xFFFFB23E),
    info: Color(0xFF4FC3E8),
    danger: Color(0xFFE43B4F),
    glassTint: Color(0xFF1A1A22),
    glassBorder: Color(0x24FFFFFF),
    headerGradient: [Color(0xFF1E3A8A), Color(0xFF172554)],
    heroBannerGradient: [Color(0xFF172554), Color(0xFF0F172A)],
    heroHeartColor: Color(0xFF36FFEB),
    cardGlowGradient: [Color(0xFF0F172A), Color(0xFF0B101D), Color(0xFF070A12)],
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
    if (other is! AppPaletteExtension) return this;
    return t < 0.5 ? this : other;
  }
}
