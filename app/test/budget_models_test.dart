import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/data/models/budget_models.dart';

void main() {
  group('BudgetDay.fromJson', () {
    test('decodes authoritative totals and purchase lines', () {
      final day = BudgetDay.fromJson({
        'date': '2026-08-12',
        'totals': {'total': 260, 'snacks': 180, 'drinks': 80},
        'items': [
          {
            'id': 'line-1',
            'date': '2026-08-12',
            'name': 'Samosa',
            'itemType': 'snack',
            'quantity': 3,
            'unitPriceRupees': 40,
            'lineTotalRupees': 120,
            'isEdited': true,
            'isManual': false,
          },
          {
            'id': 'line-2',
            'date': '2026-08-12',
            'name': 'Masala chai',
            'itemType': 'drink',
            'quantity': 2.0,
            'unitPriceRupees': 40.0,
            'lineTotalRupees': 80.0,
            'isEdited': false,
            'isManual': true,
          },
        ],
      });

      expect(day.date, '2026-08-12');
      expect(day.totals.total, 260);
      expect(day.totals.snacks, 180);
      expect(day.totals.drinks, 80);
      expect(day.items, hasLength(2));
      expect(day.items.first.itemType, BudgetItemType.snack);
      expect(day.items.first.unitPriceRupees, 40);
      expect(day.items.first.lineTotalRupees, 120);
      expect(day.items.last.itemType, BudgetItemType.drink);
      expect(day.items.last.isManual, isTrue);
    });

    test('defaults a missing optional items array to an empty collection', () {
      final day = BudgetDay.fromJson({
        'date': '2026-08-13',
        'totals': {'total': 0, 'snacks': 0, 'drinks': 0},
      });

      expect(day.items, isEmpty);
    });
  });

  group('BudgetRange.fromJson', () {
    test('decodes daily totals and item aggregates', () {
      final range = BudgetRange.fromJson({
        'start': '2026-08-10',
        'end': '2026-08-16',
        'totals': {'total': 560, 'snacks': 400, 'drinks': 160},
        'days': [
          {
            'date': '2026-08-10',
            'totals': {'total': 180, 'snacks': 120, 'drinks': 60},
          },
          {
            'date': '2026-08-11',
            'totals': {'total': 380, 'snacks': 280, 'drinks': 100},
          },
        ],
        'items': [
          {
            'name': 'Samosa',
            'itemType': 'snack',
            'quantity': 10,
            'totalRupees': 400,
          },
          {
            'name': 'Coffee',
            'itemType': 'drink',
            'quantity': 4.0,
            'totalRupees': 160.0,
          },
        ],
      });

      expect(range.start, '2026-08-10');
      expect(range.end, '2026-08-16');
      expect(range.totals.total, 560);
      expect(range.days, hasLength(2));
      expect(range.days.first.totals.snacks, 120);
      expect(range.items, hasLength(2));
      expect(range.items.first.itemType, BudgetItemType.snack);
      expect(range.items.first.quantity, 10);
      expect(range.items.first.totalRupees, 400);
      expect(range.items.last.itemType, BudgetItemType.drink);
    });

    test('defaults missing optional arrays to empty collections', () {
      final range = BudgetRange.fromJson({
        'start': '2026-08-01',
        'end': '2026-08-31',
        'totals': {'total': 0},
      });

      expect(range.days, isEmpty);
      expect(range.items, isEmpty);
      expect(range.totals.snacks, 0);
      expect(range.totals.drinks, 0);
    });
  });
}
