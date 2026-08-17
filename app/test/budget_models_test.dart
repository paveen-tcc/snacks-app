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
      expect(range.userSpendings, isEmpty);
      expect(range.totals.snacks, 0);
      expect(range.totals.drinks, 0);
    });
  });

  group('UserSpending.fromJson', () {
    test('decodes user spending with items and daily breakdown', () {
      final user = UserSpending.fromJson({
        'userId': 'user-1',
        'username': 'dhileep',
        'email': 'dhileep@example.com',
        'totalSpendRupees': 125,
        'totalOrdersCount': 2,
        'snackSpendRupees': 85,
        'drinkSpendRupees': 40,
        'items': [
          {
            'snackId': 'snack-1',
            'name': 'Smiley Veg Pizza',
            'emoji': '🍕',
            'category': 'Pizza',
            'itemType': 'snack',
            'quantity': 1,
            'unitPriceRupees': 85,
            'totalRupees': 85,
          },
          {
            'snackId': 'drink-1',
            'name': 'Cold coffee',
            'emoji': '☕',
            'category': 'Drinks',
            'itemType': 'drink',
            'quantity': 1,
            'unitPriceRupees': 40,
            'totalRupees': 40,
          },
        ],
        'dailySpend': [
          {
            'date': '2026-08-12',
            'totalRupees': 125,
            'itemCount': 2,
          },
        ],
      });

      expect(user.userId, 'user-1');
      expect(user.username, 'dhileep');
      expect(user.email, 'dhileep@example.com');
      expect(user.totalSpendRupees, 125);
      expect(user.totalOrdersCount, 2);
      expect(user.snackSpendRupees, 85);
      expect(user.drinkSpendRupees, 40);
      expect(user.items, hasLength(2));
      expect(user.items.first.name, 'Smiley Veg Pizza');
      expect(user.items.first.itemType, BudgetItemType.snack);
      expect(user.items.last.name, 'Cold coffee');
      expect(user.items.last.itemType, BudgetItemType.drink);
      expect(user.dailySpend, hasLength(1));
      expect(user.dailySpend.first.date, '2026-08-12');
      expect(user.dailySpend.first.totalRupees, 125);
    });

    test('amountForFilter and itemsForFilter behave correctly', () {
      final user = UserSpending.fromJson({
        'userId': 'user-1',
        'username': 'dhileep',
        'email': 'dhileep@example.com',
        'totalSpendRupees': 125,
        'totalOrdersCount': 2,
        'snackSpendRupees': 85,
        'drinkSpendRupees': 40,
        'items': [
          {
            'snackId': 'snack-1',
            'name': 'Pizza',
            'itemType': 'snack',
            'quantity': 1,
            'unitPriceRupees': 85,
            'totalRupees': 85,
          },
          {
            'snackId': 'drink-1',
            'name': 'Chai',
            'itemType': 'drink',
            'quantity': 1,
            'unitPriceRupees': 40,
            'totalRupees': 40,
          },
        ],
      });

      expect(user.amountForFilter(BudgetTypeFilter.all), 125);
      expect(user.amountForFilter(BudgetTypeFilter.snacks), 85);
      expect(user.amountForFilter(BudgetTypeFilter.drinks), 40);

      expect(user.itemsForFilter(BudgetTypeFilter.all), hasLength(2));
      expect(user.itemsForFilter(BudgetTypeFilter.snacks), hasLength(1));
      expect(user.itemsForFilter(BudgetTypeFilter.snacks).first.name, 'Pizza');
      expect(user.itemsForFilter(BudgetTypeFilter.drinks), hasLength(1));
      expect(user.itemsForFilter(BudgetTypeFilter.drinks).first.name, 'Chai');
    });
  });
}
