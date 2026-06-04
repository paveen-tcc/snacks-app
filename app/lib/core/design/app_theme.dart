import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_effects.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Central theme builder for the redesigned app.
///
/// Exposes [AppTheme.light] / [AppTheme.dark] (Material 3) wired from the design
/// tokens, palettes, typography and effect extensions. Screens should read
/// colors from `Theme.of(context).colorScheme` and the `context.palette /
/// context.shadows / context.glass` getters below rather than hard-coding values
/// so light/dark both stay correct.
class AppTheme {
  AppTheme._();

  static ThemeData light = _build(AppPalette.light);
  static ThemeData dark = _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final scheme = p.toColorScheme();
    final textTheme = AppTypography.textTheme(p.textPrimary);
    final shadows = p.isDark ? AppShadows.dark : AppShadows.light;
    final glass = p.isDark ? AppGlassStyle.dark : AppGlassStyle.light;

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      fontFamily: AppTypography.bodyFamily,
      extensions: <ThemeExtension<dynamic>>[
        AppPaletteExtension(p),
        shadows,
        glass,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: p.textPrimary,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: textTheme.headlineSmall,
        systemOverlayStyle: p.isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: p.background,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: p.background,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
      ),
      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rLg),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.textTertiary),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: p.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: p.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          disabledBackgroundColor: p.brand.withValues(alpha: 0.4),
          disabledForegroundColor: p.onBrand.withValues(alpha: 0.8),
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: p.border),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brand,
          textStyle: textTheme.labelLarge,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: Colors.transparent,
        modalElevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rLg),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceMuted,
        selectedColor: p.brand,
        side: BorderSide(color: p.border),
        labelStyle: textTheme.labelMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rPill),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.veg : null,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
      ),
    );
  }
}

/// Convenience accessors for the design-system theme extensions.
///
/// These fall back to brightness-appropriate defaults if the extensions aren't
/// present (e.g. a widget test using a bare `MaterialApp`), so design-system
/// widgets never crash for lack of the full [AppTheme].
extension AppThemeContext on BuildContext {
  AppPalette get palette {
    final ext = Theme.of(this).extension<AppPaletteExtension>();
    if (ext != null) return ext.palette;
    return Theme.of(this).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
  }

  AppShadows get shadows {
    return Theme.of(this).extension<AppShadows>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? AppShadows.dark
            : AppShadows.light);
  }

  AppGlassStyle get glass {
    return Theme.of(this).extension<AppGlassStyle>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? AppGlassStyle.dark
            : AppGlassStyle.light);
  }

  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
