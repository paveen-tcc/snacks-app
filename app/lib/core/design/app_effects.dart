import 'package:flutter/material.dart';

/// Soft, Airbnb-style elevation shadows exposed via the theme.
///
/// Read with `Theme.of(context).extension<AppShadows>()` (or `context.shadows`).
/// Shadows are intentionally subtle in dark mode (depth comes from surface
/// tonal steps instead).
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({
    required this.sm,
    required this.md,
    required this.lg,
  });

  final List<BoxShadow> sm;
  final List<BoxShadow> md;
  final List<BoxShadow> lg;

  static const AppShadows light = AppShadows(
    sm: [
      BoxShadow(
        color: Color(0x0F1C1C1E),
        blurRadius: 10,
        offset: Offset(0, 3),
      ),
    ],
    md: [
      BoxShadow(
        color: Color(0x141C1C1E),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
    lg: [
      BoxShadow(
        color: Color(0x1F1C1C1E),
        blurRadius: 34,
        offset: Offset(0, 16),
      ),
    ],
  );

  static const AppShadows dark = AppShadows(
    sm: [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    md: [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
    lg: [
      BoxShadow(
        color: Color(0x4D000000),
        blurRadius: 40,
        offset: Offset(0, 18),
      ),
    ],
  );

  @override
  AppShadows copyWith({
    List<BoxShadow>? sm,
    List<BoxShadow>? md,
    List<BoxShadow>? lg,
  }) =>
      AppShadows(sm: sm ?? this.sm, md: md ?? this.md, lg: lg ?? this.lg);

  @override
  AppShadows lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) return this;
    return AppShadows(
      sm: BoxShadow.lerpList(sm, other.sm, t) ?? sm,
      md: BoxShadow.lerpList(md, other.md, t) ?? md,
      lg: BoxShadow.lerpList(lg, other.lg, t) ?? lg,
    );
  }
}

/// Tuning for the liquid-glass surfaces, exposed via the theme.
///
/// Read with `Theme.of(context).extension<AppGlassStyle>()` (or `context.glass`).
@immutable
class AppGlassStyle extends ThemeExtension<AppGlassStyle> {
  const AppGlassStyle({
    required this.blurSigma,
    required this.tintOpacity,
    required this.fallbackOpacity,
    required this.borderOpacity,
    required this.highlightOpacity,
  });

  /// Gaussian blur sigma used by [BackdropFilter] when blur is enabled.
  final double blurSigma;

  /// Opacity of the glass tint painted over the blur.
  final double tintOpacity;

  /// Opacity of the tint when blur is disabled (solid fallback) — higher so the
  /// surface stays legible without a real blur behind it.
  final double fallbackOpacity;

  /// Opacity of the hairline border around the glass.
  final double borderOpacity;

  /// Opacity of the subtle top highlight gradient.
  final double highlightOpacity;

  static const AppGlassStyle light = AppGlassStyle(
    blurSigma: 18,
    tintOpacity: 0.72,
    fallbackOpacity: 0.94,
    borderOpacity: 0.45,
    highlightOpacity: 0.35,
  );

  static const AppGlassStyle dark = AppGlassStyle(
    blurSigma: 20,
    tintOpacity: 0.55,
    fallbackOpacity: 0.92,
    borderOpacity: 0.12,
    highlightOpacity: 0.08,
  );

  @override
  AppGlassStyle copyWith({
    double? blurSigma,
    double? tintOpacity,
    double? fallbackOpacity,
    double? borderOpacity,
    double? highlightOpacity,
  }) =>
      AppGlassStyle(
        blurSigma: blurSigma ?? this.blurSigma,
        tintOpacity: tintOpacity ?? this.tintOpacity,
        fallbackOpacity: fallbackOpacity ?? this.fallbackOpacity,
        borderOpacity: borderOpacity ?? this.borderOpacity,
        highlightOpacity: highlightOpacity ?? this.highlightOpacity,
      );

  @override
  AppGlassStyle lerp(ThemeExtension<AppGlassStyle>? other, double t) {
    if (other is! AppGlassStyle) return this;
    return AppGlassStyle(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t),
      tintOpacity: lerpDouble(tintOpacity, other.tintOpacity, t),
      fallbackOpacity: lerpDouble(fallbackOpacity, other.fallbackOpacity, t),
      borderOpacity: lerpDouble(borderOpacity, other.borderOpacity, t),
      highlightOpacity: lerpDouble(highlightOpacity, other.highlightOpacity, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
