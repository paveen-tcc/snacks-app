import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../local/app_database.dart';
import 'dart:convert';

class SyncEngine {
  final ApiClient _apiClient;
  final AppDatabase _localDb;

  StreamSubscription? _connectivitySub;

  SyncEngine(this._apiClient, this._localDb);

  void start() {
    // Listen for network changes to trigger sync when coming online
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (!result.contains(ConnectivityResult.none)) {
        print('⚡ Network restored, triggering sync engine...');
        _syncPendingQueue();
      }
    });
  }

  void stop() {
    _connectivitySub?.cancel();
  }

  Future<void> _syncPendingQueue() async {
    final pendingItems = await _localDb.select(_localDb.syncQueue).get();

    if (pendingItems.isEmpty) return;
    print('🔄 Processing ${pendingItems.length} queued offline actions');

    for (var item in pendingItems) {
      try {
        final payload = jsonDecode(item.payloadJson);

        // Execute the pending action
        if (item.targetTable == 'orders' && item.action == 'POST') {
          await _apiClient.dio.post('/orders', data: payload);
        } else if (item.targetTable == 'orders' && item.action == 'DELETE') {
          await _apiClient.dio.delete('/orders', data: payload);
        } else if (item.targetTable == 'drink_votes' && item.action == 'POST') {
          await _apiClient.dio.post('/drinks/vote', data: payload);
        } else if (item.targetTable == 'drink_votes' &&
            item.action == 'DELETE') {
          await _apiClient.dio.delete('/drinks/vote', data: payload);
        }

        // On success, remove from queue
        await (_localDb.delete(
          _localDb.syncQueue,
        )..where((t) => t.id.equals(item.id))).go();
        print('✅ Synced queued item: ${item.targetTable}');
      } on DioException catch (e) {
        print('❌ Failed to sync item ${item.id}: ${e.message}');
        // Drop 4xx errors — invalid/stale data that will never succeed
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode >= 400 && statusCode < 500) {
          await (_localDb.delete(
            _localDb.syncQueue,
          )..where((t) => t.id.equals(item.id))).go();
          print('🗑️ Dropped stale queue item ${item.id} ($statusCode)');
        }
      } catch (e) {
        print('❌ Unknown sync error for item ${item.id}: $e');
      }
    }
  }
}
