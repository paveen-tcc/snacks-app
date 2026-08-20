import '../../core/network/api_client.dart';
import '../local/app_database.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' hide Column;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Thrown when the server permanently rejects an order mutation (4xx) — e.g.
/// the ordering window has closed. Carries a user-facing [message] and is not
/// retried, unlike transient network failures which are queued for sync.
class OrderException implements Exception {
  final String message;
  OrderException(this.message);

  @override
  String toString() => message;
}

class OrderRepository {
  final ApiClient _apiClient;
  final AppDatabase _localDb;

  OrderRepository(this._apiClient, this._localDb);

  /// The server records a sugar-free drink by appending " (Sugar Free)" to the
  /// stored name snapshot — detect that so the local cache can remember it.
  static bool _isSugarFreeSnapshot(dynamic snapshot) =>
      snapshot is String && snapshot.endsWith('(Sugar Free)');

  /// Pull a human-readable error out of a Dio error response body, if present.
  static String? _serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    return null;
  }

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
      debugPrint('Status check failed: $e');
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
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    final pendingOrderActions = await (_localDb.select(
      _localDb.syncQueue,
    )..where((item) => item.targetTable.equals('orders'))).get();
    if (pendingOrderActions.isNotEmpty) {
      pendingOrderActions.sort((a, b) => a.id.compareTo(b.id));
      final latest = pendingOrderActions.last;
      if (latest.action == 'DELETE' && userId != null) {
        await (_localDb.delete(
          _localDb.localOrders,
        )..where((t) => t.userId.equals(userId) & t.date.equals(today))).go();
      }
      return;
    }

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
                  sugarFree: drift.Value(
                    _isSugarFreeSnapshot(orderJson['snackNameSnapshot']),
                  ),
                  snackNameSnapshot: drift.Value(
                    orderJson['snackNameSnapshot'] as String?,
                  ),
                  isDefaultAssigned: drift.Value(
                    orderJson['isDefaultAssigned'] ?? false,
                  ),
                ),
              );
        }
      }
    } catch (e) {
      debugPrint('Sync order failed: $e');
    }
  }

  // Place or update order (Offline-First)
  Future<void> placeOrder(
    List<String> snackIds, {
    Map<String, bool>? sugarFreePrefs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) throw Exception('User not logged in');

    final today = await _effectiveOrderDate();
    // Quantity is expressed as repeated snack IDs (one order row each), so
    // duplicates must be preserved end-to-end.
    final orderedSnackIds = List<String>.from(snackIds);
    if (orderedSnackIds.isEmpty) {
      throw Exception('Select at least one snack');
    }

    // Collect IDs of snacks that should be named as sugar-free
    final sugarFreeSnackIds = sugarFreePrefs?.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList() ?? <String>[];

    // 1. Save locally immediately (Optimistic response)
    final batchTimestamp = DateTime.now().millisecondsSinceEpoch;
    await _localDb.transaction(() async {
      await (_localDb.delete(
        _localDb.localOrders,
      )..where((t) => t.userId.equals(userId) & t.date.equals(today))).go();
      for (var i = 0; i < orderedSnackIds.length; i++) {
        final tempId = 'temp_${batchTimestamp}_${i}_${orderedSnackIds[i]}';
        await _localDb
            .into(_localDb.localOrders)
            .insert(
              LocalOrdersCompanion.insert(
                id: tempId,
                userId: userId,
                date: today,
                snackId: orderedSnackIds[i],
                sugarFree: drift.Value(
                  sugarFreeSnackIds.contains(orderedSnackIds[i]),
                ),
                isDefaultAssigned: const drift.Value(false),
              ),
            );
      }
    });

    // Build request payload
    final requestData = <String, dynamic>{
      'snackIds': orderedSnackIds,
      'date': today,
    };
    if (sugarFreeSnackIds.isNotEmpty) {
      requestData['sugarFreeSnackIds'] = sugarFreeSnackIds;
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
              payloadJson: jsonEncode(requestData),
            ),
          );
      return;
    }

    // 3b. Online: Send to API
    try {
      final response = await _apiClient.dio.post(
        '/orders',
        data: requestData,
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
                    sugarFree: drift.Value(
                      _isSugarFreeSnapshot(serverOrder['snackNameSnapshot']),
                    ),
                    snackNameSnapshot: drift.Value(
                      serverOrder['snackNameSnapshot'] as String?,
                    ),
                    isDefaultAssigned: drift.Value(
                      serverOrder['isDefaultAssigned'] ?? false,
                    ),
                  ),
                );
          }
        });
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status >= 400 && status < 500) {
        // Server permanently rejected the order (e.g. the window has closed).
        // Retrying will never succeed, so don't queue it. Roll the optimistic
        // local write back to the server's truth and surface the reason.
        await syncTodayOrder();
        throw OrderException(
          _serverMessage(e) ?? 'Your order could not be placed.',
        );
      }
      // Transient network/5xx failure — keep offline-first behavior and queue
      // for retry (the order is already saved locally).
      await _localDb
          .into(_localDb.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              targetTable: 'orders',
              action: 'POST',
              payloadJson: jsonEncode(requestData),
            ),
          );
      debugPrint('Order queued for sync: $e');
    }
  }

  Future<void> clearOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) throw Exception('User not logged in');

    final today = await _effectiveOrderDate();
    await (_localDb.delete(
      _localDb.localOrders,
    )..where((t) => t.userId.equals(userId) & t.date.equals(today))).go();

    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      await _localDb
          .into(_localDb.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              targetTable: 'orders',
              action: 'DELETE',
              payloadJson: jsonEncode({'date': today}),
            ),
          );
      return;
    }

    try {
      await _apiClient.dio.delete('/orders');
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status >= 400 && status < 500) {
        // Window closed (or other permanent rejection): the order can't be
        // cleared anymore. Restore the server's truth and surface the reason.
        await syncTodayOrder();
        throw OrderException(
          _serverMessage(e) ?? 'Your order could not be changed.',
        );
      }
      await _localDb
          .into(_localDb.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              targetTable: 'orders',
              action: 'DELETE',
              payloadJson: jsonEncode({'date': today}),
            ),
          );
      debugPrint('Order clear queued for sync: $e');
    }
  }
}
