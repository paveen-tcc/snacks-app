import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/msal_service.dart';
import '../di/locator.dart';
import '../../config/routes.dart';
import '../../data/repositories/auth_repository.dart';

class ApiClient {
  // Use 10.0.2.2 for Android emulator to access localhost, use localhost for iOS
  // Use localhost for iOS Simulator, use your machine IP for physical devices
  static const String baseUrl = 'http://192.168.0.137:8787/api';
  // 'https://snacks-app.paveenkumar-dev.workers.dev/api';

  late Dio _dio;
  bool _isRefreshing = false;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptor to attach JWT token to all requests
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshed = await _trySilentReauth();
              if (refreshed) {
                // Retry the original request with the new token
                final prefs = await SharedPreferences.getInstance();
                final newToken = prefs.getString('auth_token');
                final options = e.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } else {
                await _forceLogout();
              }
            } catch (_) {
              await _forceLogout();
            } finally {
              _isRefreshing = false;
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Attempt silent MSAL token refresh and exchange for a new server JWT.
  Future<bool> _trySilentReauth() async {
    final msalService = locator<MsalService>();
    final idToken = await msalService.acquireTokenSilent();
    if (idToken == null) return false;

    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ).post('/auth/microsoft', data: {'idToken': idToken});

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return true;
      }
    } catch (_) {
      // Silent reauth failed
    }
    return false;
  }

  /// Clear stored auth data and redirect to login.
  Future<void> _forceLogout() async {
    final authRepo = locator<AuthRepository>();
    await authRepo.logout();
    AppRouter.router.go('/onboarding');
  }

  Dio get dio => _dio;
}
