import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/presentation/admin/snacks_screen.dart';
import 'package:snacks_app/presentation/home/widgets/dispenser/drink_dispenser_models.dart';

void main() {
  final items = <Map<String, dynamic>>[
    {'id': 'pizza', 'name': 'Margherita', 'category': 'Pizza'},
    {'id': 'roll', 'name': 'Paneer Roll', 'category': 'Roll'},
    {'id': 'tea', 'name': 'Masala Tea', 'category': 'Drinks'},
    {'id': 'cola', 'name': 'Diet Coke', 'category': ' drinks '},
    {'id': 'shake', 'name': 'Mango Shake', 'category': 'Drinks'},
  ];

  test('separates food and drinks using the normalized Drinks category', () {
    final snacks = filterAdminMenuItems(items, drinksTab: false, query: '');
    final drinks = filterAdminMenuItems(items, drinksTab: true, query: '');

    expect(snacks.map((item) => item['id']), ['pizza', 'roll']);
    expect(drinks.map((item) => item['id']), ['tea', 'cola', 'shake']);
  });

  test('combines food category and name search', () {
    final result = filterAdminMenuItems(
      items,
      drinksTab: false,
      query: 'mar',
      category: 'Pizza',
    );

    expect(result.single['id'], 'pizza');
  });

  test('uses the Home drink classifier for format filtering', () {
    final hot = filterAdminMenuItems(
      items,
      drinksTab: true,
      query: '',
      drinkFormat: DrinkFormat.hotBrew,
    );
    final cans = filterAdminMenuItems(
      items,
      drinksTab: true,
      query: '',
      drinkFormat: DrinkFormat.can,
    );
    final cold = filterAdminMenuItems(
      items,
      drinksTab: true,
      query: 'mango',
      drinkFormat: DrinkFormat.coldJuice,
    );

    expect(hot.single['id'], 'tea');
    expect(cans.single['id'], 'cola');
    expect(cold.single['id'], 'shake');
  });
}
