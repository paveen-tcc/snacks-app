library;

/// Mapping and resolver for bundled food and drink image assets
/// bundled in `assets/images/food/` and `assets/images/drinks/`.

const Map<String, String> localFoodAssetMap = {
  // Pizzas
  'smiley veg pizza': 'assets/images/food/smiley_veg_pizza.webp',
  'chicken pizza': 'assets/images/food/chicken_pizza.webp',

  // Burgers
  'veg cheese burger': 'assets/images/food/veg_cheese_burger.webp',
  'veg burger': 'assets/images/food/veg_cheese_burger.webp',
  'chicken cheese burger': 'assets/images/food/chicken_cheese_burger.webp',
  'chicken burger': 'assets/images/food/chicken_cheese_burger.webp',

  // Shawarmas
  'shawarma': 'assets/images/food/shawarma.webp',
  'normal shawarma': 'assets/images/food/shawarma.webp',
  'schezwan shawarma': 'assets/images/food/schezwan_shawarma.webp',
  'cheese shawarma': 'assets/images/food/cheese_shawarma.webp',
  'lays shawarma': 'assets/images/food/lays_shawarma.webp',
  'chocolate shawarma': 'assets/images/food/chocolate_shawarma.webp',
  'spicy shawarma': 'assets/images/food/spicy_shawarma.webp',

  // Rolls & Frankies
  'veg frankie': 'assets/images/food/veg_frankie.webp',
  'paneer frankie': 'assets/images/food/paneer_frankie.webp',
  'chicken frankie': 'assets/images/food/chicken_frankie.webp',
  'egg frankie': 'assets/images/food/egg_frankie.webp',
  'veg roll': 'assets/images/food/veg_roll.webp',
  'paneer roll': 'assets/images/food/paneer_roll.webp',
  'chicken roll': 'assets/images/food/chicken_roll.webp',

  // Chicken & Fried Varieties
  'chilli chicken': 'assets/images/food/chilli_chicken.webp',
  'chicken nuggets': 'assets/images/food/chicken_nuggets.webp',
  'chicken pops': 'assets/images/food/chicken_pops.webp',
  'chicken wings': 'assets/images/food/chicken_wings.webp',
  'chicken lollipop': 'assets/images/food/chicken_lollipop.webp',
  'crab lollipop': 'assets/images/food/crab_lollipop.webp',
  'veg fingers': 'assets/images/food/veg_fingers.webp',
  'paneer fingers': 'assets/images/food/paneer_fingers.webp',
  'chicken fingers': 'assets/images/food/chicken_fingers.webp',
  'gobi chilli': 'assets/images/food/gobi_chilli.webp',

  // Sandwiches
  'veg sandwich': 'assets/images/food/veg_sandwich.webp',
  'veg paneer sandwich': 'assets/images/food/veg_paneer_sandwich.webp',
  'paneer sandwich': 'assets/images/food/veg_paneer_sandwich.webp',
  'mushroom sandwich': 'assets/images/food/mushroom_sandwich.webp',
  'chicken sandwich': 'assets/images/food/chicken_sandwich.webp',

  // Momos
  'veg momos': 'assets/images/food/veg_momos.webp',
  'veg momo': 'assets/images/food/veg_momos.webp',
  'paneer momos': 'assets/images/food/paneer_momos.webp',
  'paneer momo': 'assets/images/food/paneer_momos.webp',
  'chicken momos': 'assets/images/food/chicken_momos.webp',
  'chicken momo': 'assets/images/food/chicken_momos.webp',

  // Samosas
  'veg samosa': 'assets/images/food/veg_samosa.webp',
  'onion samosa': 'assets/images/food/onion_samosa.webp',
  'egg samosa': 'assets/images/food/egg_samosa.webp',
  'chicken samosa': 'assets/images/food/chicken_samosa.webp',

  // Fries & Fried items
  'french fries': 'assets/images/food/french_fries.webp',
  'fries': 'assets/images/food/french_fries.webp',

  // Chat items
  'bread omblete': 'assets/images/food/bread_omlette.webp',
  'bread omlette': 'assets/images/food/bread_omlette.webp',
  'bread omelette': 'assets/images/food/bread_omlette.webp',
  'masal poori': 'assets/images/food/masal_poori.webp',
  'masala poori': 'assets/images/food/masal_poori.webp',
  'paani poori': 'assets/images/food/paani_poori.webp',
  'pani puri': 'assets/images/food/paani_poori.webp',
  'bhel poori': 'assets/images/food/bhel_poori.webp',
  'bhel puri': 'assets/images/food/bhel_poori.webp',
  'road side kalaan': 'assets/images/food/road_side_kalaan.webp',
  'roadside kalaan': 'assets/images/food/road_side_kalaan.webp',
  'road side kalaan - egg': 'assets/images/food/road_side_kalaan_egg.webp',
  'road side kalaan egg': 'assets/images/food/road_side_kalaan_egg.webp',
  'roadside kalaan egg': 'assets/images/food/road_side_kalaan_egg.webp',
  'thattu vada set - veg': 'assets/images/food/thattu_vada_set_veg.webp',
  'thattu vada set veg': 'assets/images/food/thattu_vada_set_veg.webp',
  'thattu vada set - egg': 'assets/images/food/thattu_vada_set_egg.webp',
  'thattu vada set egg': 'assets/images/food/thattu_vada_set_egg.webp',
  'egg norukal': 'assets/images/food/egg_norukal.webp',
  'egg norukkal': 'assets/images/food/egg_norukal.webp',

  // Maggie
  'veg maggie': 'assets/images/food/veg_maggie.webp',
  'egg maggie': 'assets/images/food/egg_maggie.webp',

  // Healthy & Fruits
  'boiled egg': 'assets/images/food/boiled_egg.webp',
  'omlette': 'assets/images/food/omlette.webp',
  'omelette': 'assets/images/food/omlette.webp',
  'red banana': 'assets/images/food/red_banana.webp',
  'mixed fruit salad': 'assets/images/food/mixed_fruit_salad.webp',
  'fruit salad': 'assets/images/food/mixed_fruit_salad.webp',
  'pineapple cuttings': 'assets/images/food/pineapple_cuttings.webp',
  'watermelon cuttings': 'assets/images/food/watermelon_cuttings.webp',
  'cucumber cuttings': 'assets/images/food/cucumber_cuttings.webp',
  'guava cuttings': 'assets/images/food/guava_cuttings.webp',

  // Puddings
  'banana pudding': 'assets/images/food/banana_pudding.webp',
  'pista pudding': 'assets/images/food/pista_pudding.webp',
  'rose milk pudding': 'assets/images/food/rose_milk_pudding.webp',

  // Beverages & Drinks (in assets/images/drinks/)
  'tea': 'assets/images/drinks/tea.webp',
  'coffee': 'assets/images/drinks/coffee.webp',
  'boost': 'assets/images/drinks/boost.webp',
  'cold coffee': 'assets/images/drinks/cold_coffee.webp',
  'cold boost': 'assets/images/drinks/cold_boost.webp',
  'orange juice': 'assets/images/drinks/orange_juice.webp',
  'apple juice': 'assets/images/drinks/apple_juice.webp',
  'abc juice': 'assets/images/drinks/abc_juice.webp',
  'pomegranate juice': 'assets/images/drinks/pomegranate_juice.webp',
  'pineapple juice': 'assets/images/drinks/pineapple_juice.webp',
  'watermelon juice': 'assets/images/drinks/watermelon_juice.webp',
  'musk melon juice': 'assets/images/drinks/musk_melon_juice.webp',
  'saththukudi juice': 'assets/images/drinks/saththukudi_juice.webp',
  'carrot juice': 'assets/images/drinks/carrot_juice.webp',
  'rose milk': 'assets/images/drinks/rose_milk.webp',
  'lemon juice': 'assets/images/drinks/lemon_juice.webp',
  'lime soda - sweet': 'assets/images/drinks/lime_soda_sweet.webp',
  'lime soda sweet': 'assets/images/drinks/lime_soda_sweet.webp',
  'lime soda': 'assets/images/drinks/lime_soda_sweet.webp',
  'redbanana/dates shake': 'assets/images/drinks/red_banana_dates_shake.webp',
  'redbanana dates shake': 'assets/images/drinks/red_banana_dates_shake.webp',
  'red banana dates shake': 'assets/images/drinks/red_banana_dates_shake.webp',
  'custard apple juice': 'assets/images/drinks/custard_apple_juice.webp',
  'buttur fruit juice': 'assets/images/drinks/butter_fruit_juice.webp',
  'butter fruit juice': 'assets/images/drinks/butter_fruit_juice.webp',
  'coke': 'assets/images/drinks/coke_logo.webp',
  'diet coke': 'assets/images/drinks/diet_coke_logo.webp',
  'red bull': 'assets/images/drinks/red_bull_logo.jpg',
  'monster green': 'assets/images/drinks/monster_logo.webp',
  'monster white': 'assets/images/drinks/monster_logo.webp',
  'monster': 'assets/images/drinks/monster_logo.webp',
};

/// Normalizes a snack or drink item name and returns the local image asset path
/// if available, or null if no local asset is bundled yet.
String? resolveLocalFoodAsset(String? name) {
  if (name == null || name.trim().isEmpty) return null;

  final normalized = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  // 1. Direct dictionary match
  if (localFoodAssetMap.containsKey(normalized)) {
    return localFoodAssetMap[normalized];
  }

  // 2. Stripped hyphen / slash match
  final stripped = normalized
      .replaceAll('-', ' ')
      .replaceAll('/', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (localFoodAssetMap.containsKey(stripped)) {
    return localFoodAssetMap[stripped];
  }

  // 3. Fallback partial match for common names
  for (final entry in localFoodAssetMap.entries) {
    if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
      return entry.value;
    }
  }

  return null;
}
