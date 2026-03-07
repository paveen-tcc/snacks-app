import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../local/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' hide Column;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OrderRepository {
  final ApiClient _apiClient;
  final AppDatabase _localDb;

  OrderRepository(this._apiClient, this._localDb);

  // Get stream of today's order for reactive UI
  Stream<LocalOrder?> watchTodayOrder() async* {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) {
      yield null;
      return;
    }

    final today = DateTime.now().toIso8601String().split('T')[0];

    yield* (_localDb.select(_localDb.localOrders)
          ..where((t) => t.userId.equals(userId) & t.date.equals(today)))
        .watchSingleOrNull();
  }

  // Sync today's order from remote
  Future<void> syncTodayOrder() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    try {
      final response = await _apiClient.dio.get('/orders/today');
      if (response.statusCode == 200 && response.data['order'] != null) {
        final orderJson = response.data['order'];

        await _localDb
            .into(_localDb.localOrders)
            .insertOnConflictUpdate(
              LocalOrdersCompanion.insert(
                id: orderJson['id'],
                userId: orderJson['userId'],
                date: orderJson['date'],
                snackId: orderJson['snackId'],
                isDefaultAssigned: drift.Value(
                  orderJson['isDefaultAssigned'] ?? false,
                ),
              ),
            );
      }
    } catch (e) {
      print('Sync order failed: \$e');
    }
  }

  // Place or update order (Offline-First)
  Future<void> placeOrder(String snackId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) throw Exception('User not logged in');

    final today = DateTime.now().toIso8601String().split('T')[0];
    // Generate a temporary ID for local storage if offline
    final tempId = 'temp_\${DateTime.now().millisecondsSinceEpoch}';

    // 1. Save locally immediately (Optimistic response)
    await _localDb
        .into(_localDb.localOrders)
        .insertOnConflictUpdate(
          LocalOrdersCompanion.insert(
            id: tempId,
            userId: userId,
            date: today,
            snackId: snackId,
            isDefaultAssigned: const drift.Value(false),
          ),
        );

    // 2. Try network
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      // 3a. Offline: Queue for later sync
      await _localDb
          .into(_localDb.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              targetTable: 'orders',
              action: 'POST',
              payloadJson: jsonEncode({'snackId': snackId, 'date': today}),
            ),
          );
      return;
    }

    // 3b. Online: Send to API
    try {
      final response = await _apiClient.dio.post(
        '/orders',
        data: {'snackId': snackId, 'date': today},
      );

      if (response.statusCode == 200) {
        final serverOrder = response.data['order'];
        // Update local with server ID
        await _localDb.transaction(() async {
          await (_localDb.delete(
            _localDb.localOrders,
          )..where((t) => t.id.equals(tempId))).go();
          await _localDb
              .into(_localDb.localOrders)
              .insertOnConflictUpdate(
                LocalOrdersCompanion.insert(
                  id: serverOrder['id'],
                  userId: serverOrder['userId'],
                  date: serverOrder['date'],
                  snackId: serverOrder['snackId'],
                  isDefaultAssigned: drift.Value(
                    serverOrder['isDefaultAssigned'] ?? false,
                  ),
                ),
              );
        });
      }
    } catch (e) {
      // API failed despite having connection, queue it just in case
      await _localDb
          .into(_localDb.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              targetTable: 'orders',
              action: 'POST',
              payloadJson: jsonEncode({'snackId': snackId, 'date': today}),
            ),
          );
      throw Exception('Failed to place order, saved offline');
    }
  }
}
