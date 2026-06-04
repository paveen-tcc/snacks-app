import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'glass.dart';

/// App-level user preferences that affect theming/appearance.
///
/// Kept tiny and listenable so `main.dart` can rebuild `MaterialApp` when they
/// change. `reduceTransparency` lives on [GlassCapability] (read by glass
/// surfaces directly); this controller owns the dark-mode flag and persistence
/// for both.
class AppSettings {
  AppSettings._();

  static const _kDarkMode = 'dark_mode';
  static const _kReduceTransparency = 'reduce_transparency';

  /// Simple on/off dark mode (ignores the system setting, per user request).
  static final ValueNotifier<bool> darkMode = ValueNotifier(false);

  /// Listenable that fires when any appearance preference changes.
  static Listenable get listenable =>
      Listenable.merge([darkMode, GlassCapability.reduceTransparency]);

  /// Load persisted prefs. Defaults dark mode to the current platform
  /// brightness on first launch so the initial look matches the OS.
  static Future<void> load(SharedPreferences prefs, Brightness platform) async {
    darkMode.value =
        prefs.getBool(_kDarkMode) ?? (platform == Brightness.dark);
    GlassCapability.reduceTransparency.value =
        prefs.getBool(_kReduceTransparency) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    darkMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
  }

  static Future<void> setReduceTransparency(bool value) async {
    GlassCapability.reduceTransparency.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReduceTransparency, value);
  }
}
