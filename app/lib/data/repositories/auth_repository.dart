import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<void> loginWithMicrosoft(String idToken) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/microsoft',
        data: {'idToken': idToken},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final user = response.data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_id', user['id']);
        await prefs.setString('username', user['username'] ?? '');
        await prefs.setBool('is_admin', user['isAdmin'] ?? false);
      }
    } on DioException catch (e) {
      final serverError = e.response?.data is Map
          ? e.response?.data['error']
          : e.response?.data?.toString();
      throw Exception(
          serverError ?? '${e.type}: ${e.message}');
    }
  }

  Future<void> refreshSession() async {
    try {
      final response = await _apiClient.dio.get('/auth/session');
      if (response.statusCode == 200) {
        final token = response.data['token'];
        final user = response.data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_id', user['id']);
        await prefs.setString('username', user['username'] ?? '');
        await prefs.setBool('is_admin', user['isAdmin'] ?? false);
      }
    } on DioException catch (e) {
      final serverError = e.response?.data is Map
          ? e.response?.data['error']
          : e.response?.data?.toString();
      throw Exception(serverError ?? '${e.type}: ${e.message}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('is_admin');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }
}
