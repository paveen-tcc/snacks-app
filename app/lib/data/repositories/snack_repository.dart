import '../../core/network/api_client.dart';
import '../local/app_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/drift.dart' hide Column;

class SnackRepository {
  final ApiClient _apiClient;
  final AppDatabase _localDb;

  SnackRepository(this._apiClient, this._localDb);

  Future<void> _savePublicSettings(PublicSettings settings) async {
    await _localDb
        .into(_localDb.localSettings)
        .insertOnConflictUpdate(
          LocalSettingsCompanion.insert(
            id: const drift.Value(1),
            cutoffTime: drift.Value(settings.cutoffTime),
            advanceOrderMode: drift.Value(settings.advanceOrderMode),
            advanceWindowStart: drift.Value(settings.advanceWindowStart),
            advanceWindowEnd: drift.Value(settings.advanceWindowEnd),
          ),
        );
  }

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
                    category: json['category'] != null
                        ? drift.Value(json['category'])
                        : const drift.Value.absent(),
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
                    shareCount: drift.Value(json['shareCount'] ?? 1),
                    sortOrder: drift.Value(json['sortOrder'] ?? 0),
                  ),
                );
          }
        });
      }
    } catch (e) {
      print('Sync failed: $e');
    }
  }

  /// Fetch public settings from startup endpoint and cache them locally.
  Future<PublicSettings> fetchPublicSettings() async {
    try {
      final response = await _apiClient.dio.get('/snacks/settings');
      if (response.statusCode == 200) {
        final settings = PublicSettings.fromJson(response.data);
        await _savePublicSettings(settings);
        return settings;
      }
    } catch (e) {
      print('Settings fetch failed: $e');
    }
    final cached = await (_localDb.select(
      _localDb.localSettings,
    )..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
    return PublicSettings(
      cutoffTime: cached?.cutoffTime ?? '12:00',
      advanceOrderMode: cached?.advanceOrderMode ?? false,
      advanceWindowStart: cached?.advanceWindowStart ?? '06:00',
      advanceWindowEnd: cached?.advanceWindowEnd ?? '22:00',
    );
  }

  // Observes local drift database for reactive UI updates
  Stream<List<LocalSnack>> watchActiveSnacks() {
    return (_localDb.select(_localDb.localSnacks)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }
}

class PublicSettings {
  final String cutoffTime;
  final bool advanceOrderMode;
  final String advanceWindowStart;
  final String advanceWindowEnd;

  const PublicSettings({
    required this.cutoffTime,
    required this.advanceOrderMode,
    required this.advanceWindowStart,
    required this.advanceWindowEnd,
  });

  factory PublicSettings.fromJson(Map<String, dynamic> json) {
    return PublicSettings(
      cutoffTime: json['cutoffTime'] as String? ?? '12:00',
      advanceOrderMode: json['advanceOrderMode'] as bool? ?? false,
      advanceWindowStart: json['advanceWindowStart'] as String? ?? '06:00',
      advanceWindowEnd: json['advanceWindowEnd'] as String? ?? '22:00',
    );
  }
}
