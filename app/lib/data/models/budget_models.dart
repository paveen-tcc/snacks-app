import 'package:flutter/foundation.dart';

int _asInt(dynamic value) => (value as num?)?.toInt() ?? 0;

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
}

enum BudgetItemType {
  snack,
  drink;

  static BudgetItemType fromJson(dynamic value) =>
      value == 'drink' ? BudgetItemType.drink : BudgetItemType.snack;

  String get jsonValue => name;
}

enum BudgetTypeFilter {
  all,
  snacks,
  drinks;

  bool includes(BudgetItemType type) => switch (this) {
    BudgetTypeFilter.all => true,
    BudgetTypeFilter.snacks => type == BudgetItemType.snack,
    BudgetTypeFilter.drinks => type == BudgetItemType.drink,
  };

  int amountFrom(BudgetTotals totals) => switch (this) {
    BudgetTypeFilter.all => totals.total,
    BudgetTypeFilter.snacks => totals.snacks,
    BudgetTypeFilter.drinks => totals.drinks,
  };
}

@immutable
class BudgetTotals {
  const BudgetTotals({
    required this.total,
    required this.snacks,
    required this.drinks,
  });

  factory BudgetTotals.fromJson(Map<String, dynamic> json) => BudgetTotals(
    total: _asInt(json['total']),
    snacks: _asInt(json['snacks']),
    drinks: _asInt(json['drinks']),
  );

  static const zero = BudgetTotals(total: 0, snacks: 0, drinks: 0);

  final int total;
  final int snacks;
  final int drinks;
}

@immutable
class BudgetLine {
  const BudgetLine({
    required this.id,
    required this.date,
    required this.name,
    required this.itemType,
    required this.quantity,
    required this.unitPriceRupees,
    required this.lineTotalRupees,
    required this.isEdited,
    required this.isManual,
  });

  factory BudgetLine.fromJson(Map<String, dynamic> json) => BudgetLine(
    id: json['id'] as String? ?? '',
    date: json['date'] as String? ?? '',
    name: json['name'] as String? ?? '',
    itemType: BudgetItemType.fromJson(json['itemType']),
    quantity: _asInt(json['quantity']),
    unitPriceRupees: _asInt(json['unitPriceRupees']),
    lineTotalRupees: _asInt(json['lineTotalRupees']),
    isEdited: json['isEdited'] as bool? ?? false,
    isManual: json['isManual'] as bool? ?? false,
  );

  final String id;
  final String date;
  final String name;
  final BudgetItemType itemType;
  final int quantity;
  final int unitPriceRupees;
  final int lineTotalRupees;
  final bool isEdited;
  final bool isManual;
}

@immutable
class UserBudgetItem {
  const UserBudgetItem({
    required this.snackId,
    required this.name,
    this.emoji,
    this.category,
    required this.itemType,
    required this.quantity,
    required this.unitPriceRupees,
    required this.totalRupees,
  });

  factory UserBudgetItem.fromJson(Map<String, dynamic> json) => UserBudgetItem(
    snackId: json['snackId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    emoji: json['emoji'] as String?,
    category: json['category'] as String?,
    itemType: BudgetItemType.fromJson(json['itemType']),
    quantity: _asInt(json['quantity']),
    unitPriceRupees: _asInt(json['unitPriceRupees']),
    totalRupees: _asInt(json['totalRupees']),
  );

  final String snackId;
  final String name;
  final String? emoji;
  final String? category;
  final BudgetItemType itemType;
  final int quantity;
  final int unitPriceRupees;
  final int totalRupees;
}

@immutable
class UserDailySpend {
  const UserDailySpend({
    required this.date,
    required this.totalRupees,
    required this.itemCount,
  });

  factory UserDailySpend.fromJson(Map<String, dynamic> json) => UserDailySpend(
    date: json['date'] as String? ?? '',
    totalRupees: _asInt(json['totalRupees']),
    itemCount: _asInt(json['itemCount']),
  );

  final String date;
  final int totalRupees;
  final int itemCount;
}

@immutable
class UserSpending {
  const UserSpending({
    required this.userId,
    required this.username,
    required this.email,
    required this.totalSpendRupees,
    required this.totalOrdersCount,
    required this.snackSpendRupees,
    required this.drinkSpendRupees,
    this.items = const [],
    this.dailySpend = const [],
  });

  factory UserSpending.fromJson(Map<String, dynamic> json) => UserSpending(
    userId: json['userId'] as String? ?? '',
    username: json['username'] as String? ?? '',
    email: json['email'] as String? ?? '',
    totalSpendRupees: _asInt(json['totalSpendRupees']),
    totalOrdersCount: _asInt(json['totalOrdersCount']),
    snackSpendRupees: _asInt(json['snackSpendRupees']),
    drinkSpendRupees: _asInt(json['drinkSpendRupees']),
    items: List.unmodifiable(
      _asMapList(json['items']).map(UserBudgetItem.fromJson),
    ),
    dailySpend: List.unmodifiable(
      _asMapList(json['dailySpend']).map(UserDailySpend.fromJson),
    ),
  );

  final String userId;
  final String username;
  final String email;
  final int totalSpendRupees;
  final int totalOrdersCount;
  final int snackSpendRupees;
  final int drinkSpendRupees;
  final List<UserBudgetItem> items;
  final List<UserDailySpend> dailySpend;

  int amountForFilter(BudgetTypeFilter filter) => switch (filter) {
    BudgetTypeFilter.all => totalSpendRupees,
    BudgetTypeFilter.snacks => snackSpendRupees,
    BudgetTypeFilter.drinks => drinkSpendRupees,
  };

  List<UserBudgetItem> itemsForFilter(BudgetTypeFilter filter) =>
      items.where((item) => filter.includes(item.itemType)).toList();
}

@immutable
class BudgetDay {
  const BudgetDay({
    required this.date,
    required this.totals,
    this.items = const [],
    this.userSpendings = const [],
  });

  factory BudgetDay.fromJson(Map<String, dynamic> json) => BudgetDay(
    date: json['date'] as String? ?? '',
    totals: BudgetTotals.fromJson(_asMap(json['totals'])),
    items: List.unmodifiable(
      _asMapList(json['items']).map(BudgetLine.fromJson),
    ),
    userSpendings: List.unmodifiable(
      _asMapList(json['userSpendings']).map(UserSpending.fromJson),
    ),
  );

  final String date;
  final BudgetTotals totals;
  final List<BudgetLine> items;
  final List<UserSpending> userSpendings;
}

@immutable
class BudgetItemTotal {
  const BudgetItemTotal({
    required this.name,
    required this.itemType,
    required this.quantity,
    required this.totalRupees,
  });

  factory BudgetItemTotal.fromJson(Map<String, dynamic> json) =>
      BudgetItemTotal(
        name: json['name'] as String? ?? '',
        itemType: BudgetItemType.fromJson(json['itemType']),
        quantity: _asInt(json['quantity']),
        totalRupees: _asInt(json['totalRupees']),
      );

  final String name;
  final BudgetItemType itemType;
  final int quantity;
  final int totalRupees;
}

@immutable
class BudgetRange {
  const BudgetRange({
    required this.start,
    required this.end,
    required this.totals,
    this.days = const [],
    this.items = const [],
    this.userSpendings = const [],
  });

  factory BudgetRange.fromJson(Map<String, dynamic> json) => BudgetRange(
    start: json['start'] as String? ?? '',
    end: json['end'] as String? ?? '',
    totals: BudgetTotals.fromJson(_asMap(json['totals'])),
    days: List.unmodifiable(_asMapList(json['days']).map(BudgetDay.fromJson)),
    items: List.unmodifiable(
      _asMapList(json['items']).map(BudgetItemTotal.fromJson),
    ),
    userSpendings: List.unmodifiable(
      _asMapList(json['userSpendings']).map(UserSpending.fromJson),
    ),
  );

  final String start;
  final String end;
  final BudgetTotals totals;
  final List<BudgetDay> days;
  final List<BudgetItemTotal> items;
  final List<UserSpending> userSpendings;
}
