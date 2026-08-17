import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

const List<String> snackCategoryOrder = [
  'Pizza',
  'Sandwich',
  'Burger',
  'Fries',
  'Roll',
  'Momos',
  'Fingers Fried',
  'Chicken Varieties',
  'Samosa',
  'Chat Items',
  'Healthy',
  'Maggie',
  'Puddings',
  'Drinks',
];

const Map<String, String> snackCategoryIcons = {
  'All': '🍽️',
  'Drinks': '🥤',
  'Pizza': '🍕',
  'Sandwich': '🥪',
  'Burger': '🍔',
  'Fries': '🍟',
  'Fired': '🍟',
  'Roll': '🌯',
  'Momos': '🥟',
  'Fingers Fried': '🍗',
  'Chicken Varieties': '🍗',
  'Samosa': '🥟',
  'Chat Items': '🍲',
  'Healthy': '🥗',
  'Maggie': '🍜',
  'Puddings': '🍮',
  'General': '🍴',
};

class CategoryIconPair {
  const CategoryIconPair({
    required this.selected,
    required this.unselected,
  });
  final IconData selected;
  final IconData unselected;
}

CategoryIconPair snackCategoryIconPair(String category) {
  final cat = displaySnackCategory(category).toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');

  if (cat == 'all') {
    return const CategoryIconPair(
      selected: Symbols.shopping_basket_rounded,
      unselected: Symbols.shopping_basket,
    );
  }
  if (cat.contains('pizza')) {
    return const CategoryIconPair(
      selected: Symbols.local_pizza_rounded,
      unselected: Symbols.local_pizza,
    );
  }
  if (cat.contains('sandwich')) {
    return const CategoryIconPair(
      selected: Symbols.lunch_dining_rounded,
      unselected: Symbols.lunch_dining,
    );
  }
  if (cat.contains('burger')) {
    return const CategoryIconPair(
      selected: Symbols.lunch_dining_rounded,
      unselected: Symbols.lunch_dining,
    );
  }
  if (cat.contains('maggi') ||
      cat.contains('maggie') ||
      cat.contains('noodle') ||
      cat.contains('pasta') ||
      cat.contains('chowmein')) {
    return const CategoryIconPair(
      selected: Symbols.ramen_dining_rounded,
      unselected: Symbols.ramen_dining,
    );
  }
  if (cat.contains('chat') ||
      cat.contains('chaat') ||
      cat.contains('puri') ||
      cat.contains('bhel') ||
      cat.contains('snack') ||
      cat.contains('street')) {
    return const CategoryIconPair(
      selected: Symbols.tapas_rounded,
      unselected: Symbols.tapas,
    );
  }
  if (cat.contains('momo') ||
      cat.contains('dumpling') ||
      cat.contains('dimsum')) {
    return const CategoryIconPair(
      selected: Symbols.soup_kitchen_rounded,
      unselected: Symbols.soup_kitchen,
    );
  }
  if (cat.contains('finger')) {
    return const CategoryIconPair(
      selected: Symbols.set_meal_rounded,
      unselected: Symbols.set_meal,
    );
  }
  if (cat.contains('fries') ||
      cat.contains('fried') ||
      cat.contains('fired') ||
      cat.contains('crisp') ||
      cat.contains('chips')) {
    return const CategoryIconPair(
      selected: Symbols.fastfood_rounded,
      unselected: Symbols.fastfood,
    );
  }
  if (cat.contains('roll') ||
      cat.contains('wrap') ||
      cat.contains('kebab') ||
      cat.contains('shawarma') ||
      cat.contains('frankie')) {
    return const CategoryIconPair(
      selected: Symbols.kebab_dining_rounded,
      unselected: Symbols.kebab_dining,
    );
  }
  if (cat.contains('pudding') ||
      cat.contains('custard') ||
      cat.contains('flan') ||
      cat.contains('jelly') ||
      cat.contains('gelatin') ||
      cat.contains('ice') ||
      cat.contains('kulfi')) {
    return const CategoryIconPair(
      selected: Symbols.icecream_rounded,
      unselected: Symbols.icecream,
    );
  }
  if (cat.contains('sweet') ||
      cat.contains('dessert') ||
      cat.contains('cake') ||
      cat.contains('pastry') ||
      cat.contains('mithai') ||
      cat.contains('halwa')) {
    return const CategoryIconPair(
      selected: Symbols.cake_rounded,
      unselected: Symbols.cake,
    );
  }
  if (cat.contains('samosa') ||
      cat.contains('bakery') ||
      cat.contains('puff') ||
      cat.contains('bake')) {
    return const CategoryIconPair(
      selected: Symbols.bakery_dining_rounded,
      unselected: Symbols.bakery_dining,
    );
  }
  if (cat.contains('chicken') ||
      cat.contains('non-veg') ||
      cat.contains('meat') ||
      cat.contains('wings') ||
      cat.contains('lollipop') ||
      cat.contains('tandoor') ||
      cat.contains('varieties')) {
    return const CategoryIconPair(
      selected: Symbols.dinner_dining_rounded,
      unselected: Symbols.dinner_dining,
    );
  }
  if (cat.contains('health') ||
      cat.contains('salad') ||
      cat.contains('fruit') ||
      cat.contains('sprout') ||
      cat.contains('fresh') ||
      cat.contains('diet') ||
      cat.contains('green')) {
    return const CategoryIconPair(
      selected: Symbols.eco_rounded,
      unselected: Symbols.eco,
    );
  }
  if (cat.contains('drink') ||
      cat.contains('tea') ||
      cat.contains('coffee') ||
      cat.contains('chai') ||
      cat.contains('beverage') ||
      cat.contains('juice') ||
      cat.contains('shake') ||
      cat.contains('soda')) {
    return const CategoryIconPair(
      selected: Symbols.local_cafe_rounded,
      unselected: Symbols.local_cafe,
    );
  }
  if (cat.contains('rice') ||
      cat.contains('biryani') ||
      cat.contains('pulao') ||
      cat.contains('thali') ||
      cat.contains('meal')) {
    return const CategoryIconPair(
      selected: Symbols.rice_bowl_rounded,
      unselected: Symbols.rice_bowl,
    );
  }
  if (cat.contains('dosa') ||
      cat.contains('idli') ||
      cat.contains('vada') ||
      cat.contains('south')) {
    return const CategoryIconPair(
      selected: Symbols.breakfast_dining_rounded,
      unselected: Symbols.breakfast_dining,
    );
  }
  if (cat.contains('roti') ||
      cat.contains('paratha') ||
      cat.contains('curry') ||
      cat.contains('north')) {
    return const CategoryIconPair(
      selected: Symbols.skillet_rounded,
      unselected: Symbols.skillet,
    );
  }

  return const CategoryIconPair(
    selected: Symbols.restaurant_rounded,
    unselected: Symbols.restaurant,
  );
}

String displaySnackCategory(String? category) {
  final trimmed = category?.trim() ?? '';
  return trimmed.isEmpty ? 'General' : trimmed;
}

int snackCategoryRank(String category) {
  final index = snackCategoryOrder.indexOf(category);
  return index >= 0 ? index : snackCategoryOrder.length;
}

String normalizeSnackCategory(String? category) {
  return displaySnackCategory(category).toLowerCase();
}

String snackCategoryIcon(String category) {
  return snackCategoryIcons[category] ?? '🍽️';
}
