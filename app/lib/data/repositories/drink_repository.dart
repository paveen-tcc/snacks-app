import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../local/app_database.dart';

class DrinkRepository {
  final ApiClient _apiClient;
  final AppDatabase _localDb;

  DrinkRepository(this._apiClient, this._localDb);

  Future<List<Map<String, dynamic>>> fetchDrinks() async {
    final response = await _apiClient.dio.get('/drinks');
    return List<Map<String, dynamic>>.from(response.data['drinks']);
  }

  Future<String?> getTodayVote() async {
    try {
      final response = await _apiClient.dio.get('/drinks/vote');
      final vote = response.data['vote'];
      return _applyPendingVoteOverride(vote?['drinkId'] as String?);
    } on DioException {
      return _applyPendingVoteOverride(null);
    }
  }

  Future<void> castVote(String drinkId) async {
    final payload = {'drinkId': drinkId};
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      await _queueVoteAction('POST', payload);
      return;
    }

    try {
      await _apiClient.dio.post('/drinks/vote', data: payload);
    } catch (_) {
      await _queueVoteAction('POST', payload);
    }
  }

  Future<void> clearVote() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      await _queueVoteAction('DELETE', const <String, dynamic>{});
      return;
    }

    try {
      await _apiClient.dio.delete('/drinks/vote');
    } catch (_) {
      await _queueVoteAction('DELETE', const <String, dynamic>{});
    }
  }

  Future<void> _queueVoteAction(String action, Map<String, dynamic> payload) {
    return _localDb
        .into(_localDb.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            targetTable: 'drink_votes',
            action: action,
            payloadJson: jsonEncode(payload),
          ),
        );
  }

  Future<String?> _applyPendingVoteOverride(String? serverDrinkId) async {
    final pendingVotes = await (_localDb.select(
      _localDb.syncQueue,
    )..where((item) => item.targetTable.equals('drink_votes'))).get();
    if (pendingVotes.isEmpty) return serverDrinkId;

    pendingVotes.sort((a, b) => a.id.compareTo(b.id));
    final latest = pendingVotes.last;
    if (latest.action == 'DELETE') return null;
    if (latest.action == 'POST') {
      final payload = jsonDecode(latest.payloadJson) as Map<String, dynamic>;
      return payload['drinkId'] as String? ?? serverDrinkId;
    }
    return serverDrinkId;
  }
}
