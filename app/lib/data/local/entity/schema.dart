import 'package:drift/drift.dart';

// Employee snacks catalog cache
class LocalSnacks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  TextColumn get emoji => text().nullable()();
  BoolColumn get isVeg => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get servingSize => text().nullable()();
  IntColumn get shareCount => integer().withDefault(const Constant(1))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// User orders cache
class LocalOrders extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get date => text()(); // YYYY-MM-DD
  TextColumn get snackId => text()();
  BoolColumn get sugarFree => boolean().withDefault(const Constant(false))();
  BoolColumn get isDefaultAssigned =>
      boolean().withDefault(const Constant(false))();
  TextColumn get snackNameSnapshot => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// App Settings cache (cutoff time, holiday country, etc)
class LocalSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get cutoffTime => text().withDefault(const Constant('12:00'))();
  BoolColumn get advanceOrderMode =>
      boolean().withDefault(const Constant(false))();
  TextColumn get advanceWindowStart =>
      text().withDefault(const Constant('06:00'))();
  TextColumn get advanceWindowEnd =>
      text().withDefault(const Constant('22:00'))();

  @override
  Set<Column> get primaryKey => {id};
}

// Offline Action Queue
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text()(); // e.g. 'orders', 'drink_votes'
  TextColumn get action => text()(); // 'INSERT', 'UPDATE', 'DELETE'
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
