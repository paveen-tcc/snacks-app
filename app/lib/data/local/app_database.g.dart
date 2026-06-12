// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalSnacksTable extends LocalSnacks
    with TableInfo<$LocalSnacksTable, LocalSnack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSnacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isVegMeta = const VerificationMeta('isVeg');
  @override
  late final GeneratedColumn<bool> isVeg = GeneratedColumn<bool>(
    'is_veg',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_veg" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _servingSizeMeta = const VerificationMeta(
    'servingSize',
  );
  @override
  late final GeneratedColumn<String> servingSize = GeneratedColumn<String>(
    'serving_size',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shareCountMeta = const VerificationMeta(
    'shareCount',
  );
  @override
  late final GeneratedColumn<int> shareCount = GeneratedColumn<int>(
    'share_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    emoji,
    isVeg,
    isDefault,
    isActive,
    servingSize,
    shareCount,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_snacks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSnack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('is_veg')) {
      context.handle(
        _isVegMeta,
        isVeg.isAcceptableOrUnknown(data['is_veg']!, _isVegMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('serving_size')) {
      context.handle(
        _servingSizeMeta,
        servingSize.isAcceptableOrUnknown(
          data['serving_size']!,
          _servingSizeMeta,
        ),
      );
    }
    if (data.containsKey('share_count')) {
      context.handle(
        _shareCountMeta,
        shareCount.isAcceptableOrUnknown(data['share_count']!, _shareCountMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSnack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSnack(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
      isVeg: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_veg'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      servingSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_size'],
      ),
      shareCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}share_count'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $LocalSnacksTable createAlias(String alias) {
    return $LocalSnacksTable(attachedDatabase, alias);
  }
}

class LocalSnack extends DataClass implements Insertable<LocalSnack> {
  final String id;
  final String name;
  final String? category;
  final String? emoji;
  final bool isVeg;
  final bool isDefault;
  final bool isActive;
  final String? servingSize;
  final int shareCount;
  final int sortOrder;
  const LocalSnack({
    required this.id,
    required this.name,
    this.category,
    this.emoji,
    required this.isVeg,
    required this.isDefault,
    required this.isActive,
    this.servingSize,
    required this.shareCount,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    map['is_veg'] = Variable<bool>(isVeg);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || servingSize != null) {
      map['serving_size'] = Variable<String>(servingSize);
    }
    map['share_count'] = Variable<int>(shareCount);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  LocalSnacksCompanion toCompanion(bool nullToAbsent) {
    return LocalSnacksCompanion(
      id: Value(id),
      name: Value(name),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
      isVeg: Value(isVeg),
      isDefault: Value(isDefault),
      isActive: Value(isActive),
      servingSize: servingSize == null && nullToAbsent
          ? const Value.absent()
          : Value(servingSize),
      shareCount: Value(shareCount),
      sortOrder: Value(sortOrder),
    );
  }

  factory LocalSnack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSnack(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String?>(json['category']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      isVeg: serializer.fromJson<bool>(json['isVeg']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      servingSize: serializer.fromJson<String?>(json['servingSize']),
      shareCount: serializer.fromJson<int>(json['shareCount']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String?>(category),
      'emoji': serializer.toJson<String?>(emoji),
      'isVeg': serializer.toJson<bool>(isVeg),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isActive': serializer.toJson<bool>(isActive),
      'servingSize': serializer.toJson<String?>(servingSize),
      'shareCount': serializer.toJson<int>(shareCount),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  LocalSnack copyWith({
    String? id,
    String? name,
    Value<String?> category = const Value.absent(),
    Value<String?> emoji = const Value.absent(),
    bool? isVeg,
    bool? isDefault,
    bool? isActive,
    Value<String?> servingSize = const Value.absent(),
    int? shareCount,
    int? sortOrder,
  }) => LocalSnack(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category.present ? category.value : this.category,
    emoji: emoji.present ? emoji.value : this.emoji,
    isVeg: isVeg ?? this.isVeg,
    isDefault: isDefault ?? this.isDefault,
    isActive: isActive ?? this.isActive,
    servingSize: servingSize.present ? servingSize.value : this.servingSize,
    shareCount: shareCount ?? this.shareCount,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  LocalSnack copyWithCompanion(LocalSnacksCompanion data) {
    return LocalSnack(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      isVeg: data.isVeg.present ? data.isVeg.value : this.isVeg,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      servingSize: data.servingSize.present
          ? data.servingSize.value
          : this.servingSize,
      shareCount: data.shareCount.present
          ? data.shareCount.value
          : this.shareCount,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSnack(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('emoji: $emoji, ')
          ..write('isVeg: $isVeg, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('servingSize: $servingSize, ')
          ..write('shareCount: $shareCount, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    emoji,
    isVeg,
    isDefault,
    isActive,
    servingSize,
    shareCount,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSnack &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.emoji == this.emoji &&
          other.isVeg == this.isVeg &&
          other.isDefault == this.isDefault &&
          other.isActive == this.isActive &&
          other.servingSize == this.servingSize &&
          other.shareCount == this.shareCount &&
          other.sortOrder == this.sortOrder);
}

class LocalSnacksCompanion extends UpdateCompanion<LocalSnack> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> category;
  final Value<String?> emoji;
  final Value<bool> isVeg;
  final Value<bool> isDefault;
  final Value<bool> isActive;
  final Value<String?> servingSize;
  final Value<int> shareCount;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const LocalSnacksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.emoji = const Value.absent(),
    this.isVeg = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.servingSize = const Value.absent(),
    this.shareCount = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSnacksCompanion.insert({
    required String id,
    required String name,
    this.category = const Value.absent(),
    this.emoji = const Value.absent(),
    this.isVeg = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isActive = const Value.absent(),
    this.servingSize = const Value.absent(),
    this.shareCount = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LocalSnack> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? emoji,
    Expression<bool>? isVeg,
    Expression<bool>? isDefault,
    Expression<bool>? isActive,
    Expression<String>? servingSize,
    Expression<int>? shareCount,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (emoji != null) 'emoji': emoji,
      if (isVeg != null) 'is_veg': isVeg,
      if (isDefault != null) 'is_default': isDefault,
      if (isActive != null) 'is_active': isActive,
      if (servingSize != null) 'serving_size': servingSize,
      if (shareCount != null) 'share_count': shareCount,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSnacksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? category,
    Value<String?>? emoji,
    Value<bool>? isVeg,
    Value<bool>? isDefault,
    Value<bool>? isActive,
    Value<String?>? servingSize,
    Value<int>? shareCount,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return LocalSnacksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      isVeg: isVeg ?? this.isVeg,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      servingSize: servingSize ?? this.servingSize,
      shareCount: shareCount ?? this.shareCount,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (isVeg.present) {
      map['is_veg'] = Variable<bool>(isVeg.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (servingSize.present) {
      map['serving_size'] = Variable<String>(servingSize.value);
    }
    if (shareCount.present) {
      map['share_count'] = Variable<int>(shareCount.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSnacksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('emoji: $emoji, ')
          ..write('isVeg: $isVeg, ')
          ..write('isDefault: $isDefault, ')
          ..write('isActive: $isActive, ')
          ..write('servingSize: $servingSize, ')
          ..write('shareCount: $shareCount, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalOrdersTable extends LocalOrders
    with TableInfo<$LocalOrdersTable, LocalOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snackIdMeta = const VerificationMeta(
    'snackId',
  );
  @override
  late final GeneratedColumn<String> snackId = GeneratedColumn<String>(
    'snack_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sugarFreeMeta = const VerificationMeta(
    'sugarFree',
  );
  @override
  late final GeneratedColumn<bool> sugarFree = GeneratedColumn<bool>(
    'sugar_free',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sugar_free" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDefaultAssignedMeta = const VerificationMeta(
    'isDefaultAssigned',
  );
  @override
  late final GeneratedColumn<bool> isDefaultAssigned = GeneratedColumn<bool>(
    'is_default_assigned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default_assigned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _snackNameSnapshotMeta = const VerificationMeta(
    'snackNameSnapshot',
  );
  @override
  late final GeneratedColumn<String> snackNameSnapshot =
      GeneratedColumn<String>(
        'snack_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    date,
    snackId,
    sugarFree,
    isDefaultAssigned,
    snackNameSnapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('snack_id')) {
      context.handle(
        _snackIdMeta,
        snackId.isAcceptableOrUnknown(data['snack_id']!, _snackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_snackIdMeta);
    }
    if (data.containsKey('sugar_free')) {
      context.handle(
        _sugarFreeMeta,
        sugarFree.isAcceptableOrUnknown(data['sugar_free']!, _sugarFreeMeta),
      );
    }
    if (data.containsKey('is_default_assigned')) {
      context.handle(
        _isDefaultAssignedMeta,
        isDefaultAssigned.isAcceptableOrUnknown(
          data['is_default_assigned']!,
          _isDefaultAssignedMeta,
        ),
      );
    }
    if (data.containsKey('snack_name_snapshot')) {
      context.handle(
        _snackNameSnapshotMeta,
        snackNameSnapshot.isAcceptableOrUnknown(
          data['snack_name_snapshot']!,
          _snackNameSnapshotMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOrder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      snackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snack_id'],
      )!,
      sugarFree: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sugar_free'],
      )!,
      isDefaultAssigned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default_assigned'],
      )!,
      snackNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snack_name_snapshot'],
      ),
    );
  }

  @override
  $LocalOrdersTable createAlias(String alias) {
    return $LocalOrdersTable(attachedDatabase, alias);
  }
}

class LocalOrder extends DataClass implements Insertable<LocalOrder> {
  final String id;
  final String userId;
  final String date;
  final String snackId;
  final bool sugarFree;
  final bool isDefaultAssigned;
  final String? snackNameSnapshot;
  const LocalOrder({
    required this.id,
    required this.userId,
    required this.date,
    required this.snackId,
    required this.sugarFree,
    required this.isDefaultAssigned,
    this.snackNameSnapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['date'] = Variable<String>(date);
    map['snack_id'] = Variable<String>(snackId);
    map['sugar_free'] = Variable<bool>(sugarFree);
    map['is_default_assigned'] = Variable<bool>(isDefaultAssigned);
    if (!nullToAbsent || snackNameSnapshot != null) {
      map['snack_name_snapshot'] = Variable<String>(snackNameSnapshot);
    }
    return map;
  }

  LocalOrdersCompanion toCompanion(bool nullToAbsent) {
    return LocalOrdersCompanion(
      id: Value(id),
      userId: Value(userId),
      date: Value(date),
      snackId: Value(snackId),
      sugarFree: Value(sugarFree),
      isDefaultAssigned: Value(isDefaultAssigned),
      snackNameSnapshot: snackNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(snackNameSnapshot),
    );
  }

  factory LocalOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOrder(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      date: serializer.fromJson<String>(json['date']),
      snackId: serializer.fromJson<String>(json['snackId']),
      sugarFree: serializer.fromJson<bool>(json['sugarFree']),
      isDefaultAssigned: serializer.fromJson<bool>(json['isDefaultAssigned']),
      snackNameSnapshot: serializer.fromJson<String?>(
        json['snackNameSnapshot'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'date': serializer.toJson<String>(date),
      'snackId': serializer.toJson<String>(snackId),
      'sugarFree': serializer.toJson<bool>(sugarFree),
      'isDefaultAssigned': serializer.toJson<bool>(isDefaultAssigned),
      'snackNameSnapshot': serializer.toJson<String?>(snackNameSnapshot),
    };
  }

  LocalOrder copyWith({
    String? id,
    String? userId,
    String? date,
    String? snackId,
    bool? sugarFree,
    bool? isDefaultAssigned,
    Value<String?> snackNameSnapshot = const Value.absent(),
  }) => LocalOrder(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    date: date ?? this.date,
    snackId: snackId ?? this.snackId,
    sugarFree: sugarFree ?? this.sugarFree,
    isDefaultAssigned: isDefaultAssigned ?? this.isDefaultAssigned,
    snackNameSnapshot: snackNameSnapshot.present
        ? snackNameSnapshot.value
        : this.snackNameSnapshot,
  );
  LocalOrder copyWithCompanion(LocalOrdersCompanion data) {
    return LocalOrder(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      date: data.date.present ? data.date.value : this.date,
      snackId: data.snackId.present ? data.snackId.value : this.snackId,
      sugarFree: data.sugarFree.present ? data.sugarFree.value : this.sugarFree,
      isDefaultAssigned: data.isDefaultAssigned.present
          ? data.isDefaultAssigned.value
          : this.isDefaultAssigned,
      snackNameSnapshot: data.snackNameSnapshot.present
          ? data.snackNameSnapshot.value
          : this.snackNameSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrder(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('date: $date, ')
          ..write('snackId: $snackId, ')
          ..write('sugarFree: $sugarFree, ')
          ..write('isDefaultAssigned: $isDefaultAssigned, ')
          ..write('snackNameSnapshot: $snackNameSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    date,
    snackId,
    sugarFree,
    isDefaultAssigned,
    snackNameSnapshot,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOrder &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.date == this.date &&
          other.snackId == this.snackId &&
          other.sugarFree == this.sugarFree &&
          other.isDefaultAssigned == this.isDefaultAssigned &&
          other.snackNameSnapshot == this.snackNameSnapshot);
}

class LocalOrdersCompanion extends UpdateCompanion<LocalOrder> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> date;
  final Value<String> snackId;
  final Value<bool> sugarFree;
  final Value<bool> isDefaultAssigned;
  final Value<String?> snackNameSnapshot;
  final Value<int> rowid;
  const LocalOrdersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.date = const Value.absent(),
    this.snackId = const Value.absent(),
    this.sugarFree = const Value.absent(),
    this.isDefaultAssigned = const Value.absent(),
    this.snackNameSnapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOrdersCompanion.insert({
    required String id,
    required String userId,
    required String date,
    required String snackId,
    this.sugarFree = const Value.absent(),
    this.isDefaultAssigned = const Value.absent(),
    this.snackNameSnapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       date = Value(date),
       snackId = Value(snackId);
  static Insertable<LocalOrder> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? date,
    Expression<String>? snackId,
    Expression<bool>? sugarFree,
    Expression<bool>? isDefaultAssigned,
    Expression<String>? snackNameSnapshot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (date != null) 'date': date,
      if (snackId != null) 'snack_id': snackId,
      if (sugarFree != null) 'sugar_free': sugarFree,
      if (isDefaultAssigned != null) 'is_default_assigned': isDefaultAssigned,
      if (snackNameSnapshot != null) 'snack_name_snapshot': snackNameSnapshot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? date,
    Value<String>? snackId,
    Value<bool>? sugarFree,
    Value<bool>? isDefaultAssigned,
    Value<String?>? snackNameSnapshot,
    Value<int>? rowid,
  }) {
    return LocalOrdersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      snackId: snackId ?? this.snackId,
      sugarFree: sugarFree ?? this.sugarFree,
      isDefaultAssigned: isDefaultAssigned ?? this.isDefaultAssigned,
      snackNameSnapshot: snackNameSnapshot ?? this.snackNameSnapshot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (snackId.present) {
      map['snack_id'] = Variable<String>(snackId.value);
    }
    if (sugarFree.present) {
      map['sugar_free'] = Variable<bool>(sugarFree.value);
    }
    if (isDefaultAssigned.present) {
      map['is_default_assigned'] = Variable<bool>(isDefaultAssigned.value);
    }
    if (snackNameSnapshot.present) {
      map['snack_name_snapshot'] = Variable<String>(snackNameSnapshot.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrdersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('date: $date, ')
          ..write('snackId: $snackId, ')
          ..write('sugarFree: $sugarFree, ')
          ..write('isDefaultAssigned: $isDefaultAssigned, ')
          ..write('snackNameSnapshot: $snackNameSnapshot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _cutoffTimeMeta = const VerificationMeta(
    'cutoffTime',
  );
  @override
  late final GeneratedColumn<String> cutoffTime = GeneratedColumn<String>(
    'cutoff_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('12:00'),
  );
  static const VerificationMeta _advanceOrderModeMeta = const VerificationMeta(
    'advanceOrderMode',
  );
  @override
  late final GeneratedColumn<bool> advanceOrderMode = GeneratedColumn<bool>(
    'advance_order_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("advance_order_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _advanceWindowStartMeta =
      const VerificationMeta('advanceWindowStart');
  @override
  late final GeneratedColumn<String> advanceWindowStart =
      GeneratedColumn<String>(
        'advance_window_start',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('06:00'),
      );
  static const VerificationMeta _advanceWindowEndMeta = const VerificationMeta(
    'advanceWindowEnd',
  );
  @override
  late final GeneratedColumn<String> advanceWindowEnd = GeneratedColumn<String>(
    'advance_window_end',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('22:00'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cutoffTime,
    advanceOrderMode,
    advanceWindowStart,
    advanceWindowEnd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cutoff_time')) {
      context.handle(
        _cutoffTimeMeta,
        cutoffTime.isAcceptableOrUnknown(data['cutoff_time']!, _cutoffTimeMeta),
      );
    }
    if (data.containsKey('advance_order_mode')) {
      context.handle(
        _advanceOrderModeMeta,
        advanceOrderMode.isAcceptableOrUnknown(
          data['advance_order_mode']!,
          _advanceOrderModeMeta,
        ),
      );
    }
    if (data.containsKey('advance_window_start')) {
      context.handle(
        _advanceWindowStartMeta,
        advanceWindowStart.isAcceptableOrUnknown(
          data['advance_window_start']!,
          _advanceWindowStartMeta,
        ),
      );
    }
    if (data.containsKey('advance_window_end')) {
      context.handle(
        _advanceWindowEndMeta,
        advanceWindowEnd.isAcceptableOrUnknown(
          data['advance_window_end']!,
          _advanceWindowEndMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cutoffTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cutoff_time'],
      )!,
      advanceOrderMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}advance_order_mode'],
      )!,
      advanceWindowStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}advance_window_start'],
      )!,
      advanceWindowEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}advance_window_end'],
      )!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final int id;
  final String cutoffTime;
  final bool advanceOrderMode;
  final String advanceWindowStart;
  final String advanceWindowEnd;
  const LocalSetting({
    required this.id,
    required this.cutoffTime,
    required this.advanceOrderMode,
    required this.advanceWindowStart,
    required this.advanceWindowEnd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cutoff_time'] = Variable<String>(cutoffTime);
    map['advance_order_mode'] = Variable<bool>(advanceOrderMode);
    map['advance_window_start'] = Variable<String>(advanceWindowStart);
    map['advance_window_end'] = Variable<String>(advanceWindowEnd);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(
      id: Value(id),
      cutoffTime: Value(cutoffTime),
      advanceOrderMode: Value(advanceOrderMode),
      advanceWindowStart: Value(advanceWindowStart),
      advanceWindowEnd: Value(advanceWindowEnd),
    );
  }

  factory LocalSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
      id: serializer.fromJson<int>(json['id']),
      cutoffTime: serializer.fromJson<String>(json['cutoffTime']),
      advanceOrderMode: serializer.fromJson<bool>(json['advanceOrderMode']),
      advanceWindowStart: serializer.fromJson<String>(
        json['advanceWindowStart'],
      ),
      advanceWindowEnd: serializer.fromJson<String>(json['advanceWindowEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cutoffTime': serializer.toJson<String>(cutoffTime),
      'advanceOrderMode': serializer.toJson<bool>(advanceOrderMode),
      'advanceWindowStart': serializer.toJson<String>(advanceWindowStart),
      'advanceWindowEnd': serializer.toJson<String>(advanceWindowEnd),
    };
  }

  LocalSetting copyWith({
    int? id,
    String? cutoffTime,
    bool? advanceOrderMode,
    String? advanceWindowStart,
    String? advanceWindowEnd,
  }) => LocalSetting(
    id: id ?? this.id,
    cutoffTime: cutoffTime ?? this.cutoffTime,
    advanceOrderMode: advanceOrderMode ?? this.advanceOrderMode,
    advanceWindowStart: advanceWindowStart ?? this.advanceWindowStart,
    advanceWindowEnd: advanceWindowEnd ?? this.advanceWindowEnd,
  );
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      id: data.id.present ? data.id.value : this.id,
      cutoffTime: data.cutoffTime.present
          ? data.cutoffTime.value
          : this.cutoffTime,
      advanceOrderMode: data.advanceOrderMode.present
          ? data.advanceOrderMode.value
          : this.advanceOrderMode,
      advanceWindowStart: data.advanceWindowStart.present
          ? data.advanceWindowStart.value
          : this.advanceWindowStart,
      advanceWindowEnd: data.advanceWindowEnd.present
          ? data.advanceWindowEnd.value
          : this.advanceWindowEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
          ..write('id: $id, ')
          ..write('cutoffTime: $cutoffTime, ')
          ..write('advanceOrderMode: $advanceOrderMode, ')
          ..write('advanceWindowStart: $advanceWindowStart, ')
          ..write('advanceWindowEnd: $advanceWindowEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cutoffTime,
    advanceOrderMode,
    advanceWindowStart,
    advanceWindowEnd,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSetting &&
          other.id == this.id &&
          other.cutoffTime == this.cutoffTime &&
          other.advanceOrderMode == this.advanceOrderMode &&
          other.advanceWindowStart == this.advanceWindowStart &&
          other.advanceWindowEnd == this.advanceWindowEnd);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<int> id;
  final Value<String> cutoffTime;
  final Value<bool> advanceOrderMode;
  final Value<String> advanceWindowStart;
  final Value<String> advanceWindowEnd;
  const LocalSettingsCompanion({
    this.id = const Value.absent(),
    this.cutoffTime = const Value.absent(),
    this.advanceOrderMode = const Value.absent(),
    this.advanceWindowStart = const Value.absent(),
    this.advanceWindowEnd = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.cutoffTime = const Value.absent(),
    this.advanceOrderMode = const Value.absent(),
    this.advanceWindowStart = const Value.absent(),
    this.advanceWindowEnd = const Value.absent(),
  });
  static Insertable<LocalSetting> custom({
    Expression<int>? id,
    Expression<String>? cutoffTime,
    Expression<bool>? advanceOrderMode,
    Expression<String>? advanceWindowStart,
    Expression<String>? advanceWindowEnd,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cutoffTime != null) 'cutoff_time': cutoffTime,
      if (advanceOrderMode != null) 'advance_order_mode': advanceOrderMode,
      if (advanceWindowStart != null)
        'advance_window_start': advanceWindowStart,
      if (advanceWindowEnd != null) 'advance_window_end': advanceWindowEnd,
    });
  }

  LocalSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? cutoffTime,
    Value<bool>? advanceOrderMode,
    Value<String>? advanceWindowStart,
    Value<String>? advanceWindowEnd,
  }) {
    return LocalSettingsCompanion(
      id: id ?? this.id,
      cutoffTime: cutoffTime ?? this.cutoffTime,
      advanceOrderMode: advanceOrderMode ?? this.advanceOrderMode,
      advanceWindowStart: advanceWindowStart ?? this.advanceWindowStart,
      advanceWindowEnd: advanceWindowEnd ?? this.advanceWindowEnd,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cutoffTime.present) {
      map['cutoff_time'] = Variable<String>(cutoffTime.value);
    }
    if (advanceOrderMode.present) {
      map['advance_order_mode'] = Variable<bool>(advanceOrderMode.value);
    }
    if (advanceWindowStart.present) {
      map['advance_window_start'] = Variable<String>(advanceWindowStart.value);
    }
    if (advanceWindowEnd.present) {
      map['advance_window_end'] = Variable<String>(advanceWindowEnd.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('id: $id, ')
          ..write('cutoffTime: $cutoffTime, ')
          ..write('advanceOrderMode: $advanceOrderMode, ')
          ..write('advanceWindowStart: $advanceWindowStart, ')
          ..write('advanceWindowEnd: $advanceWindowEnd')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetTable,
    action,
    payloadJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String targetTable;
  final String action;
  final String payloadJson;
  final DateTime createdAt;
  const SyncQueueData({
    required this.id,
    required this.targetTable,
    required this.action,
    required this.payloadJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['action'] = Variable<String>(action);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      action: Value(action),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      action: serializer.fromJson<String>(json['action']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'action': serializer.toJson<String>(action),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? targetTable,
    String? action,
    String? payloadJson,
    DateTime? createdAt,
  }) => SyncQueueData(
    id: id ?? this.id,
    targetTable: targetTable ?? this.targetTable,
    action: action ?? this.action,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      action: data.action.present ? data.action.value : this.action,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, targetTable, action, payloadJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.action == this.action &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> targetTable;
  final Value<String> action;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.action = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String targetTable,
    required String action,
    required String payloadJson,
    this.createdAt = const Value.absent(),
  }) : targetTable = Value(targetTable),
       action = Value(action),
       payloadJson = Value(payloadJson);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? targetTable,
    Expression<String>? action,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (action != null) 'action': action,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? targetTable,
    Value<String>? action,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      action: action ?? this.action,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalSnacksTable localSnacks = $LocalSnacksTable(this);
  late final $LocalOrdersTable localOrders = $LocalOrdersTable(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localSnacks,
    localOrders,
    localSettings,
    syncQueue,
  ];
}

typedef $$LocalSnacksTableCreateCompanionBuilder =
    LocalSnacksCompanion Function({
      required String id,
      required String name,
      Value<String?> category,
      Value<String?> emoji,
      Value<bool> isVeg,
      Value<bool> isDefault,
      Value<bool> isActive,
      Value<String?> servingSize,
      Value<int> shareCount,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$LocalSnacksTableUpdateCompanionBuilder =
    LocalSnacksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> category,
      Value<String?> emoji,
      Value<bool> isVeg,
      Value<bool> isDefault,
      Value<bool> isActive,
      Value<String?> servingSize,
      Value<int> shareCount,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$LocalSnacksTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSnacksTable> {
  $$LocalSnacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVeg => $composableBuilder(
    column: $table.isVeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shareCount => $composableBuilder(
    column: $table.shareCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSnacksTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSnacksTable> {
  $$LocalSnacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVeg => $composableBuilder(
    column: $table.isVeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shareCount => $composableBuilder(
    column: $table.shareCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSnacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSnacksTable> {
  $$LocalSnacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<bool> get isVeg =>
      $composableBuilder(column: $table.isVeg, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shareCount => $composableBuilder(
    column: $table.shareCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$LocalSnacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSnacksTable,
          LocalSnack,
          $$LocalSnacksTableFilterComposer,
          $$LocalSnacksTableOrderingComposer,
          $$LocalSnacksTableAnnotationComposer,
          $$LocalSnacksTableCreateCompanionBuilder,
          $$LocalSnacksTableUpdateCompanionBuilder,
          (
            LocalSnack,
            BaseReferences<_$AppDatabase, $LocalSnacksTable, LocalSnack>,
          ),
          LocalSnack,
          PrefetchHooks Function()
        > {
  $$LocalSnacksTableTableManager(_$AppDatabase db, $LocalSnacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSnacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSnacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSnacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<bool> isVeg = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> servingSize = const Value.absent(),
                Value<int> shareCount = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSnacksCompanion(
                id: id,
                name: name,
                category: category,
                emoji: emoji,
                isVeg: isVeg,
                isDefault: isDefault,
                isActive: isActive,
                servingSize: servingSize,
                shareCount: shareCount,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> category = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<bool> isVeg = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> servingSize = const Value.absent(),
                Value<int> shareCount = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSnacksCompanion.insert(
                id: id,
                name: name,
                category: category,
                emoji: emoji,
                isVeg: isVeg,
                isDefault: isDefault,
                isActive: isActive,
                servingSize: servingSize,
                shareCount: shareCount,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSnacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSnacksTable,
      LocalSnack,
      $$LocalSnacksTableFilterComposer,
      $$LocalSnacksTableOrderingComposer,
      $$LocalSnacksTableAnnotationComposer,
      $$LocalSnacksTableCreateCompanionBuilder,
      $$LocalSnacksTableUpdateCompanionBuilder,
      (
        LocalSnack,
        BaseReferences<_$AppDatabase, $LocalSnacksTable, LocalSnack>,
      ),
      LocalSnack,
      PrefetchHooks Function()
    >;
typedef $$LocalOrdersTableCreateCompanionBuilder =
    LocalOrdersCompanion Function({
      required String id,
      required String userId,
      required String date,
      required String snackId,
      Value<bool> sugarFree,
      Value<bool> isDefaultAssigned,
      Value<String?> snackNameSnapshot,
      Value<int> rowid,
    });
typedef $$LocalOrdersTableUpdateCompanionBuilder =
    LocalOrdersCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> date,
      Value<String> snackId,
      Value<bool> sugarFree,
      Value<bool> isDefaultAssigned,
      Value<String?> snackNameSnapshot,
      Value<int> rowid,
    });

class $$LocalOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snackId => $composableBuilder(
    column: $table.snackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sugarFree => $composableBuilder(
    column: $table.sugarFree,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefaultAssigned => $composableBuilder(
    column: $table.isDefaultAssigned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snackNameSnapshot => $composableBuilder(
    column: $table.snackNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snackId => $composableBuilder(
    column: $table.snackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sugarFree => $composableBuilder(
    column: $table.sugarFree,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefaultAssigned => $composableBuilder(
    column: $table.isDefaultAssigned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snackNameSnapshot => $composableBuilder(
    column: $table.snackNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get snackId =>
      $composableBuilder(column: $table.snackId, builder: (column) => column);

  GeneratedColumn<bool> get sugarFree =>
      $composableBuilder(column: $table.sugarFree, builder: (column) => column);

  GeneratedColumn<bool> get isDefaultAssigned => $composableBuilder(
    column: $table.isDefaultAssigned,
    builder: (column) => column,
  );

  GeneratedColumn<String> get snackNameSnapshot => $composableBuilder(
    column: $table.snackNameSnapshot,
    builder: (column) => column,
  );
}

class $$LocalOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalOrdersTable,
          LocalOrder,
          $$LocalOrdersTableFilterComposer,
          $$LocalOrdersTableOrderingComposer,
          $$LocalOrdersTableAnnotationComposer,
          $$LocalOrdersTableCreateCompanionBuilder,
          $$LocalOrdersTableUpdateCompanionBuilder,
          (
            LocalOrder,
            BaseReferences<_$AppDatabase, $LocalOrdersTable, LocalOrder>,
          ),
          LocalOrder,
          PrefetchHooks Function()
        > {
  $$LocalOrdersTableTableManager(_$AppDatabase db, $LocalOrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> snackId = const Value.absent(),
                Value<bool> sugarFree = const Value.absent(),
                Value<bool> isDefaultAssigned = const Value.absent(),
                Value<String?> snackNameSnapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion(
                id: id,
                userId: userId,
                date: date,
                snackId: snackId,
                sugarFree: sugarFree,
                isDefaultAssigned: isDefaultAssigned,
                snackNameSnapshot: snackNameSnapshot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String date,
                required String snackId,
                Value<bool> sugarFree = const Value.absent(),
                Value<bool> isDefaultAssigned = const Value.absent(),
                Value<String?> snackNameSnapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion.insert(
                id: id,
                userId: userId,
                date: date,
                snackId: snackId,
                sugarFree: sugarFree,
                isDefaultAssigned: isDefaultAssigned,
                snackNameSnapshot: snackNameSnapshot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalOrdersTable,
      LocalOrder,
      $$LocalOrdersTableFilterComposer,
      $$LocalOrdersTableOrderingComposer,
      $$LocalOrdersTableAnnotationComposer,
      $$LocalOrdersTableCreateCompanionBuilder,
      $$LocalOrdersTableUpdateCompanionBuilder,
      (
        LocalOrder,
        BaseReferences<_$AppDatabase, $LocalOrdersTable, LocalOrder>,
      ),
      LocalOrder,
      PrefetchHooks Function()
    >;
typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<int> id,
      Value<String> cutoffTime,
      Value<bool> advanceOrderMode,
      Value<String> advanceWindowStart,
      Value<String> advanceWindowEnd,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<int> id,
      Value<String> cutoffTime,
      Value<bool> advanceOrderMode,
      Value<String> advanceWindowStart,
      Value<String> advanceWindowEnd,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cutoffTime => $composableBuilder(
    column: $table.cutoffTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get advanceOrderMode => $composableBuilder(
    column: $table.advanceOrderMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get advanceWindowStart => $composableBuilder(
    column: $table.advanceWindowStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get advanceWindowEnd => $composableBuilder(
    column: $table.advanceWindowEnd,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cutoffTime => $composableBuilder(
    column: $table.cutoffTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get advanceOrderMode => $composableBuilder(
    column: $table.advanceOrderMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get advanceWindowStart => $composableBuilder(
    column: $table.advanceWindowStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get advanceWindowEnd => $composableBuilder(
    column: $table.advanceWindowEnd,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cutoffTime => $composableBuilder(
    column: $table.cutoffTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get advanceOrderMode => $composableBuilder(
    column: $table.advanceOrderMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get advanceWindowStart => $composableBuilder(
    column: $table.advanceWindowStart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get advanceWindowEnd => $composableBuilder(
    column: $table.advanceWindowEnd,
    builder: (column) => column,
  );
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSetting,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSetting,
            BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
          ),
          LocalSetting,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> cutoffTime = const Value.absent(),
                Value<bool> advanceOrderMode = const Value.absent(),
                Value<String> advanceWindowStart = const Value.absent(),
                Value<String> advanceWindowEnd = const Value.absent(),
              }) => LocalSettingsCompanion(
                id: id,
                cutoffTime: cutoffTime,
                advanceOrderMode: advanceOrderMode,
                advanceWindowStart: advanceWindowStart,
                advanceWindowEnd: advanceWindowEnd,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> cutoffTime = const Value.absent(),
                Value<bool> advanceOrderMode = const Value.absent(),
                Value<String> advanceWindowStart = const Value.absent(),
                Value<String> advanceWindowEnd = const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                id: id,
                cutoffTime: cutoffTime,
                advanceOrderMode: advanceOrderMode,
                advanceWindowStart: advanceWindowStart,
                advanceWindowEnd: advanceWindowEnd,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSetting,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSetting,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
      ),
      LocalSetting,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String targetTable,
      required String action,
      required String payloadJson,
      Value<DateTime> createdAt,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> targetTable,
      Value<String> action,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                targetTable: targetTable,
                action: action,
                payloadJson: payloadJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String targetTable,
                required String action,
                required String payloadJson,
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                targetTable: targetTable,
                action: action,
                payloadJson: payloadJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalSnacksTableTableManager get localSnacks =>
      $$LocalSnacksTableTableManager(_db, _db.localSnacks);
  $$LocalOrdersTableTableManager get localOrders =>
      $$LocalOrdersTableTableManager(_db, _db.localOrders);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
