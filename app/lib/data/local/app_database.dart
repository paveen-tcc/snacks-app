import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'entity/schema.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [LocalSnacks, LocalOrders, LocalSettings, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(localSnacks, localSnacks.category);
      }
      if (from < 3) {
        await m.deleteTable('local_settings');
        await m.createTable(localSettings);
      }
      if (from < 4) {
        await m.addColumn(localSnacks, localSnacks.shareCount);
      }
      if (from < 5) {
        await m.deleteTable('local_snacks');
        await m.createTable(localSnacks);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'snacks_db.sqlite'));

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
