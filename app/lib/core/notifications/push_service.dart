import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

/// Background/terminated message handler. Must be a top-level (or static)
/// function annotated with `@pragma('vm:entry-point')`. For a simple reminder
/// with a `notification` payload Android shows the tray notification itself, so
/// there is nothing to do here — but the handler must be registered.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Owns Firebase Cloud Messaging: requests notification permission, fetches the
/// device FCM token and registers it with the server so the daily "order
/// closing soon" cron can target this device. Every method is a no-op when
/// Firebase isn't configured (no google-services.json yet), so the app keeps
/// working without push.
class PushService {
  final ApiClient _apiClient;
  PushService(this._apiClient);

  bool _listenersAttached = false;
  bool _registrationRetryScheduled = false;

  bool get _available => Firebase.apps.isNotEmpty;

  /// Attach the token-refresh listener once so a rotated token is re-registered
  /// without waiting for the next app launch. Safe to call repeatedly.
  void attachListeners() {
    if (!_available || _listenersAttached) return;
    _listenersAttached = true;
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _sendToken(token);
    });
  }

  /// Request permission (shows the Android 13+ dialog), fetch the FCM token and
  /// register it for the signed-in user. No-op if Firebase isn't configured or
  /// no user is logged in.
  Future<void> registerForCurrentUser() async {
    try {
      if (!_available) return;

      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('auth_token')) return;

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      attachListeners();

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _waitForApnsToken(messaging);
        if (apnsToken == null) {
          if (kDebugMode) {
            debugPrint('Push registration skipped: APNs token unavailable');
          }
          _scheduleRegistrationRetry();
          return;
        }
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        final sent = await _sendToken(token);
        if (!sent) _scheduleRegistrationRetry();
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Push registration failed: $error');
      }
      // Best-effort: a failed registration is retried on the next app open or
      // token refresh, so don't surface or block on it.
    }
  }

  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 40; attempt += 1) {
      final token = await messaging.getAPNSToken();
      if (token != null && token.isNotEmpty) return token;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  Future<bool> _sendToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('auth_token')) return false;

      await _apiClient.dio.post(
        '/push/token',
        data: {'token': token, 'platform': _platform},
      );
      if (kDebugMode) {
        debugPrint('Push token registered as $_platform');
      }
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Push token registration POST failed: $error');
      }
      // Best-effort: a failed registration is retried on the next app open or
      // token refresh, so don't surface or block on it.
      return false;
    }
  }

  void _scheduleRegistrationRetry() {
    if (_registrationRetryScheduled) return;
    _registrationRetryScheduled = true;
    unawaited(
      Future<void>.delayed(const Duration(seconds: 30), () async {
        _registrationRetryScheduled = false;
        await registerForCurrentUser();
      }),
    );
  }

  /// Drop this device's token on logout so a logged-out phone stops receiving
  /// reminders for the previous user.
  Future<void> unregister() async {
    if (!_available) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _apiClient.dio.delete('/push/token', data: {'token': token});
      }
      await messaging.deleteToken();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Push unregister failed: $error');
      }
      // Ignore — logout proceeds regardless.
    }
  }

  String get _platform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return defaultTargetPlatform.name;
    }
  }
}
