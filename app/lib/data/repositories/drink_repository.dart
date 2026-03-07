import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class DrinkRepository {
  final ApiClient _apiClient;

  DrinkRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> fetchDrinks() async {
    final response = await _apiClient.dio.get('/drinks');
    return List<Map<String, dynamic>>.from(response.data['drinks']);
  }

  Future<String?> getTodayVote() async {
    try {
      final response = await _apiClient.dio.get('/drinks/vote');
      final vote = response.data['vote'];
      return vote?['drinkId'] as String?;
    } on DioException {
      return null;
    }
  }

  Future<void> castVote(String drinkId) async {
    await _apiClient.dio.post('/drinks/vote', data: {'drinkId': drinkId});
  }
}
