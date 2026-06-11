import 'dart:convert';

// ignore: depend_on_referenced_packages
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snacks_app/core/network/api_client.dart';
import 'package:snacks_app/data/local/app_database.dart';
import 'package:snacks_app/data/repositories/order_repository.dart';

class _OfflineConnectivity extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.none];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late OrderRepository repo;

  setUp(() {
    ConnectivityPlatform.instance = _OfflineConnectivity();
    SharedPreferences.setMockInitialValues({'user_id': 'user-1'});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = OrderRepository(ApiClient(), db);
  });

  tearDown(() async {
    await db.close();
  });

  test('placeOrder keeps duplicate snack IDs (quantity > 1)', () async {
    await repo.placeOrder(['snack-a', 'snack-a', 'snack-b']);

    final rows = await db.select(db.localOrders).get();
    expect(rows, hasLength(3));
    expect(
      rows.map((r) => r.snackId).toList()..sort(),
      ['snack-a', 'snack-a', 'snack-b'],
    );
    // Each duplicate must get its own primary key.
    expect(rows.map((r) => r.id).toSet(), hasLength(3));

    final queued = await db.select(db.syncQueue).get();
    expect(queued, hasLength(1));
    final payload = jsonDecode(queued.single.payloadJson);
    expect(payload['snackIds'], ['snack-a', 'snack-a', 'snack-b']);
  });

  test('placeOrder replaces the previous order for the day', () async {
    await repo.placeOrder(['snack-a', 'snack-a']);
    await repo.placeOrder(['snack-a']);

    final rows = await db.select(db.localOrders).get();
    expect(rows, hasLength(1));
    expect(rows.single.snackId, 'snack-a');
  });

  test('placeOrder persists per-drink sugar-free flag locally and in payload',
      () async {
    await repo.placeOrder(
      ['snack-a', 'snack-b'],
      sugarFreePrefs: {'snack-a': true},
    );

    final byId = {
      for (final r in await db.select(db.localOrders).get()) r.snackId: r,
    };
    expect(byId['snack-a']!.sugarFree, isTrue);
    expect(byId['snack-b']!.sugarFree, isFalse);

    final queued = await db.select(db.syncQueue).get();
    final payload = jsonDecode(queued.single.payloadJson);
    expect(payload['sugarFreeSnackIds'], ['snack-a']);
  });
}
