import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snacks_app/core/design/app_accent.dart';
import 'package:snacks_app/core/design/app_colors.dart';
import 'package:snacks_app/core/design/app_settings.dart';
import 'package:snacks_app/core/design/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppAccent & Dynamic Theming Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AppAccent.fromId resolves valid ids and defaults to sapphire', () {
      expect(AppAccent.fromId('sapphire'), AppAccent.sapphire);
      expect(AppAccent.fromId('violet'), AppAccent.violet);
      expect(AppAccent.fromId('sunset'), AppAccent.sunset);
      expect(AppAccent.fromId('emerald'), AppAccent.emerald);
      expect(AppAccent.fromId('ruby'), AppAccent.ruby);
      expect(AppAccent.fromId('amethyst'), AppAccent.amethyst);
      expect(AppAccent.fromId('unknown_color'), AppAccent.sapphire);
      expect(AppAccent.fromId(null), AppAccent.sapphire);
    });

    test('AppPalette.create produces accurate dynamic palettes for all accents', () {
      for (final accent in AppAccent.values) {
        final lightPalette = AppPalette.create(
          brightness: Brightness.light,
          accent: accent,
        );
        expect(lightPalette.brightness, Brightness.light);
        expect(lightPalette.brand, accent.lightBrand);
        expect(lightPalette.headerGradient, accent.lightHeaderGradient);
        expect(lightPalette.heroBannerGradient, accent.lightHeroBannerGradient);
        expect(lightPalette.heroHeartColor, accent.heroHeartColor);
        expect(lightPalette.cardGlowGradient, accent.lightCardGlow);

        final darkPalette = AppPalette.create(
          brightness: Brightness.dark,
          accent: accent,
        );
        expect(darkPalette.brightness, Brightness.dark);
        expect(darkPalette.brand, accent.darkBrand);
        expect(darkPalette.headerGradient, accent.darkHeaderGradient);
        expect(darkPalette.heroBannerGradient, accent.darkHeroBannerGradient);
        expect(darkPalette.heroHeartColor, accent.heroHeartColor);
        expect(darkPalette.cardGlowGradient, accent.darkCardGlow);
      }
    });

    test('AppSettings updates and notifies on accent change', () async {
      final prefs = await SharedPreferences.getInstance();
      await AppSettings.load(prefs, Brightness.light);

      expect(AppSettings.accentColor.value, AppAccent.sapphire);

      int notifyCount = 0;
      AppSettings.listenable.addListener(() {
        notifyCount++;
      });

      await AppSettings.setAccent(AppAccent.violet);
      expect(AppSettings.accentColor.value, AppAccent.violet);
      expect(notifyCount, greaterThan(0));

      final reloadedPrefs = await SharedPreferences.getInstance();
      expect(reloadedPrefs.getString('accent_color_id'), 'violet');
    });

    test('AppTheme.buildTheme builds valid ThemeData for all 6 accents', () {
      for (final accent in AppAccent.values) {
        final lightTheme = AppTheme.buildTheme(Brightness.light, accent);
        expect(lightTheme.colorScheme.primary, accent.lightBrand);

        final darkTheme = AppTheme.buildTheme(Brightness.dark, accent);
        expect(darkTheme.colorScheme.primary, accent.darkBrand);
      }
    });
  });
}
