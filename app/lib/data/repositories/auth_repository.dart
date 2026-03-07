import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<void> register(String username, String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {'username': username, 'email': email},
      );

      if (response.statusCode == 201) {
        final token = response.data['token'];
        final user = response.data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_id', user['id']);
        await prefs.setString('username', user['username'] ?? '');
        await prefs.setBool('is_admin', user['isAdmin'] ?? false);
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Registration failed');
    }
  }

  Future<void> login(String email) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email},
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
      throw Exception(e.response?.data['error'] ?? 'Login failed');
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
