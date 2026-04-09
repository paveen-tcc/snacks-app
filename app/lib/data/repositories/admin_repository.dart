import '../../core/network/api_client.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> getAllSnacks() async {
    final r = await _apiClient.dio.get('/admin/snacks');
    return List<Map<String, dynamic>>.from(r.data['snacks']);
  }

  Future<void> updateSnack(String id, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/admin/snacks/$id', data: data);
  }

  Future<void> addSnack(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/admin/snacks', data: data);
  }

  Future<void> addSnacksBulk(List<Map<String, dynamic>> snacks) async {
    await _apiClient.dio.post('/admin/snacks/bulk', data: {'snacks': snacks});
  }

  Future<void> deleteSnack(String id) async {
    await _apiClient.dio.delete('/admin/snacks/$id');
  }

  Future<Map<String, dynamic>> getSettings() async {
    final r = await _apiClient.dio.get('/admin/settings');
    return Map<String, dynamic>.from(r.data['settings']);
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await _apiClient.dio.put(
      '/admin/settings',
      data: {'key': key, 'value': value},
    );
  }

  Future<Map<String, dynamic>> getSummary() async {
    final r = await _apiClient.dio.get('/admin/summary');
    return Map<String, dynamic>.from(r.data);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final r = await _apiClient.dio.get('/admin/users');
    return List<Map<String, dynamic>>.from(r.data['users']);
  }

  Future<void> updateUserAdmin(String id, bool isAdmin) async {
    await _apiClient.dio.post(
      '/admin/users/$id/admin',
      data: {'isAdmin': isAdmin},
    );
  }

  Future<List<Map<String, dynamic>>> getHolidays() async {
    final r = await _apiClient.dio.get('/admin/holidays');
    return List<Map<String, dynamic>>.from(r.data['holidays']);
  }

  Future<void> addHoliday(String date, String name) async {
    await _apiClient.dio.post(
      '/admin/holidays',
      data: {'date': date, 'name': name},
    );
  }

  Future<void> deleteHoliday(String id) async {
    await _apiClient.dio.delete('/admin/holidays/$id');
  }
}
