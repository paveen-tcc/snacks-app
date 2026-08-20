library;

/// Mapping and resolver for transparent PNG food & drink image assets
/// bundled in `assets/images/food/` and `assets/images/drinks/`.

const Map<String, String> localFoodAssetMap = {
  // Pizzas
  'smiley veg pizza': 'assets/images/food/smiley_veg_pizza.png',
  'chicken pizza': 'assets/images/food/chicken_pizza.png',

  // Burgers
  'veg cheese burger': 'assets/images/food/veg_cheese_burger.png',
  'veg burger': 'assets/images/food/veg_cheese_burger.png',
  'chicken cheese burger': 'assets/images/food/chicken_cheese_burger.png',
  'chicken burger': 'assets/images/food/chicken_cheese_burger.png',

  // Shawarmas
  'shawarma': 'assets/images/food/shawarma.png',
  'normal shawarma': 'assets/images/food/shawarma.png',
  'schezwan shawarma': 'assets/images/food/schezwan_shawarma.png',
  'cheese shawarma': 'assets/images/food/cheese_shawarma.png',
  'lays shawarma': 'assets/images/food/lays_shawarma.png',
  'chocolate shawarma': 'assets/images/food/chocolate_shawarma.png',
  'spicy shawarma': 'assets/images/food/spicy_shawarma.png',

  // Rolls & Frankies
  'veg frankie': 'assets/images/food/veg_frankie.png',
  'paneer frankie': 'assets/images/food/paneer_frankie.png',
  'chicken frankie': 'assets/images/food/chicken_frankie.png',
  'egg frankie': 'assets/images/food/egg_frankie.png',
  'veg roll': 'assets/images/food/veg_roll.png',
  'paneer roll': 'assets/images/food/paneer_roll.png',
  'chicken roll': 'assets/images/food/chicken_roll.png',

  // Chicken & Fried Varieties
  'chilli chicken': 'assets/images/food/chilli_chicken.png',
  'chicken nuggets': 'assets/images/food/chicken_nuggets.png',
  'chicken pops': 'assets/images/food/chicken_pops.png',
  'chicken wings': 'assets/images/food/chicken_wings.png',
  'chicken lollipop': 'assets/images/food/chicken_lollipop.png',
  'crab lollipop': 'assets/images/food/crab_lollipop.png',
  'veg fingers': 'assets/images/food/veg_fingers.png',
  'paneer fingers': 'assets/images/food/paneer_fingers.png',
  'chicken fingers': 'assets/images/food/chicken_fingers.png',
  'gobi chilli': 'assets/images/food/gobi_chilli.png',

  // Sandwiches
  'veg sandwich': 'assets/images/food/veg_sandwich.png',
  'veg paneer sandwich': 'assets/images/food/veg_paneer_sandwich.png',
  'paneer sandwich': 'assets/images/food/veg_paneer_sandwich.png',
  'mushroom sandwich': 'assets/images/food/mushroom_sandwich.png',
  'chicken sandwich': 'assets/images/food/chicken_sandwich.png',

  // Momos
  'veg momos': 'assets/images/food/veg_momos.png',
  'veg momo': 'assets/images/food/veg_momos.png',
  'paneer momos': 'assets/images/food/paneer_momos.png',
  'paneer momo': 'assets/images/food/paneer_momos.png',
  'chicken momos': 'assets/images/food/chicken_momos.png',
  'chicken momo': 'assets/images/food/chicken_momos.png',

  // Samosas
  'veg samosa': 'assets/images/food/veg_samosa.png',
  'onion samosa': 'assets/images/food/onion_samosa.png',
  'egg samosa': 'assets/images/food/egg_samosa.png',
  'chicken samosa': 'assets/images/food/chicken_samosa.png',

  // Fries & Fried items
  'french fries': 'assets/images/food/french_fries.png',
  'fries': 'assets/images/food/french_fries.png',

  // Chat items
  'bread omblete': 'assets/images/food/bread_omlette.png',
  'bread omlette': 'assets/images/food/bread_omlette.png',
  'bread omelette': 'assets/images/food/bread_omlette.png',
  'masal poori': 'assets/images/food/masal_poori.png',
  'masala poori': 'assets/images/food/masal_poori.png',
  'paani poori': 'assets/images/food/paani_poori.png',
  'pani puri': 'assets/images/food/paani_poori.png',
  'bhel poori': 'assets/images/food/bhel_poori.png',
  'bhel puri': 'assets/images/food/bhel_poori.png',
  'road side kalaan': 'assets/images/food/road_side_kalaan.png',
  'roadside kalaan': 'assets/images/food/road_side_kalaan.png',
  'road side kalaan - egg': 'assets/images/food/road_side_kalaan_egg.png',
  'road side kalaan egg': 'assets/images/food/road_side_kalaan_egg.png',
  'roadside kalaan egg': 'assets/images/food/road_side_kalaan_egg.png',
  'thattu vada set - veg': 'assets/images/food/thattu_vada_set_veg.png',
  'thattu vada set veg': 'assets/images/food/thattu_vada_set_veg.png',
  'thattu vada set - egg': 'assets/images/food/thattu_vada_set_egg.png',
  'thattu vada set egg': 'assets/images/food/thattu_vada_set_egg.png',
  'egg norukal': 'assets/images/food/egg_norukal.png',
  'egg norukkal': 'assets/images/food/egg_norukal.png',

  // Maggie
  'veg maggie': 'assets/images/food/veg_maggie.png',
  'egg maggie': 'assets/images/food/egg_maggie.png',

  // Healthy & Fruits
  'boiled egg': 'assets/images/food/boiled_egg.png',
  'omlette': 'assets/images/food/omlette.png',
  'omelette': 'assets/images/food/omlette.png',
  'red banana': 'assets/images/food/red_banana.png',
  'mixed fruit salad': 'assets/images/food/mixed_fruit_salad.png',
  'fruit salad': 'assets/images/food/mixed_fruit_salad.png',
  'pineapple cuttings': 'assets/images/food/pineapple_cuttings.png',
  'watermelon cuttings': 'assets/images/food/watermelon_cuttings.png',
  'cucumber cuttings': 'assets/images/food/cucumber_cuttings.png',
  'guava cuttings': 'assets/images/food/guava_cuttings.png',

  // Puddings
  'banana pudding': 'assets/images/food/banana_pudding.png',
  'pista pudding': 'assets/images/food/pista_pudding.png',
  'rose milk pudding': 'assets/images/food/rose_milk_pudding.png',

  // Beverages & Drinks (in assets/images/drinks/)
  'tea': 'assets/images/drinks/tea.png',
  'coffee': 'assets/images/drinks/coffee.png',
  'boost': 'assets/images/drinks/boost.png',
  'cold coffee': 'assets/images/drinks/cold_coffee.png',
  'cold boost': 'assets/images/drinks/cold_boost.png',
  'orange juice': 'assets/images/drinks/orange_juice.png',
  'apple juice': 'assets/images/drinks/apple_juice.png',
  'abc juice': 'assets/images/drinks/abc_juice.png',
  'pomegranate juice': 'assets/images/drinks/pomegranate_juice.png',
  'pineapple juice': 'assets/images/drinks/pineapple_juice.png',
  'watermelon juice': 'assets/images/drinks/watermelon_juice.png',
  'musk melon juice': 'assets/images/drinks/musk_melon_juice.png',
  'saththukudi juice': 'assets/images/drinks/saththukudi_juice.png',
  'carrot juice': 'assets/images/drinks/carrot_juice.png',
  'rose milk': 'assets/images/drinks/rose_milk.png',
  'lemon juice': 'assets/images/drinks/lemon_juice.png',
  'lime soda - sweet': 'assets/images/drinks/lime_soda_sweet.png',
  'lime soda sweet': 'assets/images/drinks/lime_soda_sweet.png',
  'lime soda': 'assets/images/drinks/lime_soda_sweet.png',
  'redbanana/dates shake': 'assets/images/drinks/red_banana_dates_shake.png',
  'redbanana dates shake': 'assets/images/drinks/red_banana_dates_shake.png',
  'red banana dates shake': 'assets/images/drinks/red_banana_dates_shake.png',
  'custard apple juice': 'assets/images/drinks/custard_apple_juice.png',
  'buttur fruit juice': 'assets/images/drinks/butter_fruit_juice.png',
  'butter fruit juice': 'assets/images/drinks/butter_fruit_juice.png',
  'coke': 'assets/images/drinks/coke_logo.png',
  'diet coke': 'assets/images/drinks/diet_coke_logo.png',
  'red bull': 'assets/images/drinks/red_bull_logo.jpg',
  'monster green': 'assets/images/drinks/monster_logo.jpg',
  'monster white': 'assets/images/drinks/monster_logo.jpg',
  'monster': 'assets/images/drinks/monster_logo.jpg',
};

/// Normalizes a snack or drink item name and returns the local PNG asset path
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
