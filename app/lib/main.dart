import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/design/app_theme.dart';
import 'core/design/app_settings.dart';
import 'core/notifications/push_service.dart';
import 'config/routes.dart';
import 'core/di/locator.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Brand fonts are bundled — never fetch fonts at runtime (offline-first).
  GoogleFonts.config.allowRuntimeFetching = false;

  // Firebase powers order-reminder push notifications. Config comes from the
  // FlutterFire-generated firebase_options.dart (`flutterfire configure`), so
  // the same call works on Android and iOS. Guarded so a startup failure never
  // blocks the app.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init skipped (push disabled): $e');
  }

  await setupLocator();

  // Restore appearance preferences (dark mode + reduce transparency).
  final prefs = await SharedPreferences.getInstance();
  await AppSettings.load(
    prefs,
    PlatformDispatcher.instance.platformBrightness,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild when dark-mode or reduce-transparency preferences change.
    return ListenableBuilder(
      listenable: AppSettings.listenable,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Snacks App',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode:
              AppSettings.darkMode.value ? ThemeMode.dark : ThemeMode.light,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
