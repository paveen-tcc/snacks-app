import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../local/app_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' hide Column;

class SnackRepository {
  final ApiClient _apiClient;
  final AppDatabase _localDb;

  SnackRepository(this._apiClient, this._localDb);

  Future<void> syncSnacks() async {
    // Check connectivity first
    final List<ConnectivityResult> connectivityResult = await (Connectivity()
        .checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return; // Offline, rely on cache
    }

    try {
      final response = await _apiClient.dio.get('/snacks');
      if (response.statusCode == 200) {
        final snacksList = response.data['snacks'] as List;

        // Write to Drift Local DB (Offline-first approach)
        await _localDb.transaction(() async {
          // Simplest sync: clear and insert fresh remote copy
          await _localDb.delete(_localDb.localSnacks).go();

          for (var json in snacksList) {
            await _localDb
                .into(_localDb.localSnacks)
                .insert(
                  LocalSnacksCompanion.insert(
                    id: json['id'],
                    name: json['name'],
                    emoji: json['emoji'] != null
                        ? drift.Value(json['emoji'])
                        : const drift.Value.absent(),
                    description: json['description'] != null
                        ? drift.Value(json['description'])
                        : const drift.Value.absent(),
                    isVeg: drift.Value(json['isVeg'] ?? true),
                    isDefault: drift.Value(json['isDefault'] ?? false),
                    isActive: drift.Value(json['isActive'] ?? true),
                    servingSize: json['servingSize'] != null
                        ? drift.Value(json['servingSize'])
                        : const drift.Value.absent(),
                    sortOrder: drift.Value(json['sortOrder'] ?? 0),
                  ),
                );
          }
        });
      }
    } catch (e) {
      print('Sync failed: \$e');
    }
  }

  // Observes local drift database for reactive UI updates
  Stream<List<LocalSnack>> watchActiveSnacks() {
    return (_localDb.select(_localDb.localSnacks)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }
}
