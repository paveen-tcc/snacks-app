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
class BudgetDay {
  const BudgetDay({
    required this.date,
    required this.totals,
    this.items = const [],
  });

  factory BudgetDay.fromJson(Map<String, dynamic> json) => BudgetDay(
    date: json['date'] as String? ?? '',
    totals: BudgetTotals.fromJson(_asMap(json['totals'])),
    items: List.unmodifiable(
      _asMapList(json['items']).map(BudgetLine.fromJson),
    ),
  );

  final String date;
  final BudgetTotals totals;
  final List<BudgetLine> items;
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
  });

  factory BudgetRange.fromJson(Map<String, dynamic> json) => BudgetRange(
    start: json['start'] as String? ?? '',
    end: json['end'] as String? ?? '',
    totals: BudgetTotals.fromJson(_asMap(json['totals'])),
    days: List.unmodifiable(_asMapList(json['days']).map(BudgetDay.fromJson)),
    items: List.unmodifiable(
      _asMapList(json['items']).map(BudgetItemTotal.fromJson),
    ),
  );

  final String start;
  final String end;
  final BudgetTotals totals;
  final List<BudgetDay> days;
  final List<BudgetItemTotal> items;
}
