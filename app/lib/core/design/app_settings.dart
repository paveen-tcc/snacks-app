import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_accent.dart';

/// App-level user preferences that affect theming/appearance.
///
/// Kept tiny and listenable so `main.dart` can rebuild `MaterialApp` when dark
/// mode or accent color changes.
class AppSettings {
  AppSettings._();

  static const _kDarkMode = 'dark_mode';
  static const _kAccentColor = 'accent_color_id';

  /// Simple on/off dark mode (ignores the system setting, per user request).
  static final ValueNotifier<bool> darkMode = ValueNotifier(false);

  /// Active accent theme color.
  static final ValueNotifier<AppAccent> accentColor =
      ValueNotifier(AppAccent.sapphire);

  static Listenable get listenable =>
      Listenable.merge([darkMode, accentColor]);

  /// Load persisted prefs. Defaults dark mode to the current platform
  /// brightness on first launch so the initial look matches the OS.
  static Future<void> load(SharedPreferences prefs, Brightness platform) async {
    darkMode.value = prefs.getBool(_kDarkMode) ?? (platform == Brightness.dark);
    final accentId = prefs.getString(_kAccentColor);
    accentColor.value = AppAccent.fromId(accentId);
  }

  static Future<void> setDarkMode(bool value) async {
    darkMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
  }

  static Future<void> setAccent(AppAccent accent) async {
    accentColor.value = accent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccentColor, accent.id);
  }
}
