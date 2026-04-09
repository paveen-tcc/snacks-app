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

  Future<String> _effectiveOrderDate() async {
    final settings = await (_localDb.select(
      _localDb.localSettings,
    )..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
    final offsetDays = settings?.advanceOrderMode == true ? 1 : 0;
    final date = DateTime.now().toUtc().add(Duration(days: offsetDays));
    return date.toIso8601String().split('T')[0];
  }

  /// Check if today is open for ordering (not a holiday/shutdown day).
  /// Returns {isOpen, reason?, type?}.
  Future<Map<String, dynamic>> fetchTodayStatus() async {
    try {
      final response = await _apiClient.dio.get('/orders/status');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      print('Status check failed: $e');
    }
    // Default to open if check fails (offline-first, don't block users)
    return {'isOpen': true};
  }

  // Get stream of today's orders for reactive UI
  Stream<List<LocalOrder>> watchTodayOrder() async* {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) {
      yield const [];
      return;
    }

    final today = await _effectiveOrderDate();

    yield* (_localDb.select(
      _localDb.localOrders,
    )..where((t) => t.userId.equals(userId) & t.date.equals(today))).watch();
  }

  // Sync today's order from remote
  Future<void> syncTodayOrder() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) return;
    final today = await _effectiveOrderDate();

    try {
      final response = await _apiClient.dio.get('/orders/today');
      if (response.statusCode == 200) {
        final ordersJson = List<Map<String, dynamic>>.from(
          response.data['orders'] ?? const [],
        );
        final serverUserId = ordersJson.isNotEmpty
            ? ordersJson.first['userId'] as String
            : (await SharedPreferences.getInstance()).getString('user_id');
        if (serverUserId == null) return;

        await (_localDb.delete(_localDb.localOrders)..where(
              (t) => t.userId.equals(serverUserId) & t.date.equals(today),
            ))
            .go();

        for (final orderJson in ordersJson) {
          await _localDb
              .into(_localDb.localOrders)
              .insert(
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
      }
    } catch (e) {
      print('Sync order failed: $e');
    }
  }

  // Place or update order (Offline-First)
  Future<void> placeOrder(List<String> snackIds) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) throw Exception('User not logged in');

    final today = await _effectiveOrderDate();
    final normalizedSnackIds = snackIds.toSet().toList();
    if (normalizedSnackIds.isEmpty) {
      throw Exception('Select at least one snack');
    }

    // 1. Save locally immediately (Optimistic response)
    await (_localDb.delete(
      _localDb.localOrders,
    )..where((t) => t.userId.equals(userId) & t.date.equals(today))).go();
    for (final snackId in normalizedSnackIds) {
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_$snackId';
      await _localDb
          .into(_localDb.localOrders)
          .insert(
            LocalOrdersCompanion.insert(
              id: tempId,
              userId: userId,
              date: today,
              snackId: snackId,
              isDefaultAssigned: const drift.Value(false),
            ),
          );
    }

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
              payloadJson: jsonEncode({
                'snackIds': normalizedSnackIds,
                'date': today,
              }),
            ),
          );
      return;
    }

    // 3b. Online: Send to API
    try {
      final response = await _apiClient.dio.post(
        '/orders',
        data: {'snackIds': normalizedSnackIds, 'date': today},
      );

      if (response.statusCode == 200) {
        final serverOrders = List<Map<String, dynamic>>.from(
          response.data['orders'] ?? const [],
        );
        // Update local with server ID
        await _localDb.transaction(() async {
          await (_localDb.delete(
            _localDb.localOrders,
          )..where((t) => t.userId.equals(userId) & t.date.equals(today))).go();
          for (final serverOrder in serverOrders) {
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
          }
        });
      }
    } catch (e) {
      // API failed despite having connection — queue for sync, don't throw
      // (order is already saved locally, offline-first behavior)
      await _localDb
          .into(_localDb.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              targetTable: 'orders',
              action: 'POST',
              payloadJson: jsonEncode({
                'snackIds': normalizedSnackIds,
                'date': today,
              }),
            ),
          );
      print('Order queued for sync: $e');
    }
  }
}
