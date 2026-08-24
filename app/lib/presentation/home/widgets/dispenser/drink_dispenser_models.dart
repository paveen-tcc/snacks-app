import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/constants/food_assets.dart';
import '../../../../data/local/app_database.dart';

/// The 3 distinct beverage presentation formats.
enum DrinkFormat { coldJuice, hotBrew, can }

String drinkFormatLabel(DrinkFormat format) => switch (format) {
  DrinkFormat.coldJuice => 'Cold Brews',
  DrinkFormat.hotBrew => 'Hot Brews',
  DrinkFormat.can => 'Tins',
};

IconData drinkFormatIcon(DrinkFormat format) => switch (format) {
  DrinkFormat.coldJuice => Symbols.local_drink_rounded,
  DrinkFormat.hotBrew => Symbols.coffee_rounded,
  DrinkFormat.can => Symbols.sports_bar_rounded,
};

/// Metadata and visual properties for a drink item in the 3D dispenser.
class DrinkPresentation {
  const DrinkPresentation({
    required this.format,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.iconData,
    required this.subtitle,
    this.canBrand,
    this.model3dPath,
    this.logoAssetPath,
  });

  final DrinkFormat format;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final IconData iconData;
  final String subtitle;
  final String? canBrand;
  final String? model3dPath;
  final String? logoAssetPath;

  static DrinkPresentation fromSnack(LocalSnack snack) => fromName(snack.name);

  static DrinkPresentation fromName(String snackName) {
    final name = snackName.toLowerCase().trim();
    final localAsset = resolveLocalFoodAsset(snackName);

    // 1. Canned / Carbonated Drinks
    if (name.contains('red bull') || name.contains('redbull')) {
      return DrinkPresentation(
        format: DrinkFormat.can,
        primaryColor: const Color(0xFF00205B),
        secondaryColor: const Color(0xFFC0C0C8),
        accentColor: const Color(0xFFEB1026),
        iconData: Symbols.bolt_rounded,
        subtitle: 'Energy Drink • 250ml',
        canBrand: 'REDBULL',
        model3dPath: 'assets/models/red_bull_can.glb',
        logoAssetPath: localAsset ?? 'assets/images/drinks/red_bull_logo.jpg',
      );
    }
    if (name.contains('monster')) {
      final isUltra =
          name.contains('ultra') ||
          name.contains('white') ||
          name.contains('zero');
      return DrinkPresentation(
        format: DrinkFormat.can,
        primaryColor: isUltra
            ? const Color(0xFFF5F5F5)
            : const Color(0xFF141414),
        secondaryColor: isUltra
            ? const Color(0xFFBDBDBD)
            : const Color(0xFF242424),
        accentColor: isUltra
            ? const Color(0xFF00B0FF)
            : const Color(0xFF39FF14),
        iconData: Symbols.electric_bolt_rounded,
        subtitle: isUltra ? 'Zero Ultra • 350ml' : 'Energy Drink • 350ml',
        canBrand: 'MONSTER',
        model3dPath: isUltra
            ? 'assets/models/monster_ultra_zero.glb'
            : 'assets/models/monster_green.glb',
        logoAssetPath: localAsset ?? 'assets/images/drinks/monster_logo.webp',
      );
    }
    if (name.contains('diet coke') ||
        name.contains('coke zero') ||
        name.contains('diet cola')) {
      return DrinkPresentation(
        format: DrinkFormat.can,
        primaryColor: const Color(0xFF909096),
        secondaryColor: const Color(0xFF5A5A62),
        accentColor: const Color(0xFFE51C23),
        iconData: Symbols.local_drink_rounded,
        subtitle: 'Zero Sugar • 300ml',
        canBrand: 'DIET_COKE',
        model3dPath: 'assets/models/diet_coke_can.glb',
        logoAssetPath: localAsset ?? 'assets/images/drinks/diet_coke_logo.webp',
      );
    }
    if (name.contains('coke') ||
        name.contains('coca') ||
        name.contains('cola')) {
      return DrinkPresentation(
        format: DrinkFormat.can,
        primaryColor: const Color(0xFFE51C23),
        secondaryColor: const Color(0xFF9E0B0F),
        accentColor: const Color(0xFFFFFFFF),
        iconData: Symbols.local_drink_rounded,
        subtitle: 'Carbonated • 300ml',
        canBrand: 'COKE',
        model3dPath: 'assets/models/coke.glb',
        logoAssetPath: localAsset ?? 'assets/images/drinks/coke_logo.webp',
      );
    }
    if (name.contains('sprite') ||
        name.contains('7up') ||
        name.contains('seven up')) {
      return DrinkPresentation(
        format: DrinkFormat.can,
        primaryColor: const Color(0xFF008B47),
        secondaryColor: const Color(0xFF005826),
        accentColor: const Color(0xFFFFEB3B),
        iconData: Symbols.nutrition_rounded,
        subtitle: 'Lemon Lime • 300ml',
        canBrand: 'SPRITE',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('thums') ||
        name.contains('pepsi') ||
        name.contains('fanta') ||
        name.contains('can') ||
        name.contains('tin')) {
      return DrinkPresentation(
        format: DrinkFormat.can,
        primaryColor: const Color(0xFF0D47A1),
        secondaryColor: const Color(0xFF072759),
        accentColor: const Color(0xFFFF5252),
        iconData: Symbols.sports_bar_rounded,
        subtitle: 'Chilled Can • 300ml',
        canBrand: 'SODA',
        logoAssetPath: localAsset,
      );
    }

    // 2. Cold Brews & Shakes & Fresh Juices
    if (name.contains('orange') || name.contains('citrus')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFFF9100),
        secondaryColor: const Color(0xFFE65100),
        accentColor: const Color(0xFFFFE082),
        iconData: Symbols.water_drop_rounded,
        subtitle: 'Fresh Squeezed Orange Juice',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('cold boost') ||
        name.contains('iced boost') ||
        name.contains('boost cold')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFF8D4F1E),
        secondaryColor: const Color(0xFF5C2C0D),
        accentColor: const Color(0xFFFFAB91),
        iconData: Symbols.local_drink_rounded,
        subtitle: 'Chilled Rich Malt Boost',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('cold coffee') ||
        name.contains('iced coffee') ||
        name.contains('cold brew') ||
        name.contains('frappe')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFF6F4E37),
        secondaryColor: const Color(0xFF3B2219),
        accentColor: const Color(0xFFD7CCC8),
        iconData: Symbols.local_cafe_rounded,
        subtitle: 'Chilled Creamy Cold Coffee',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('pomegranate') || name.contains('pom')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFC2185B),
        secondaryColor: const Color(0xFF880E4F),
        accentColor: const Color(0xFFF8BBD0),
        iconData: Symbols.water_full_rounded,
        subtitle: 'Fresh Ruby Pomegranate Juice',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('rose milk') || name.contains('rosemilk')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFF06292),
        secondaryColor: const Color(0xFFC2185B),
        accentColor: const Color(0xFFFCE4EC),
        iconData: Symbols.local_drink_rounded,
        subtitle: 'Chilled Fragrant Rose Milk',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('abc')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFF880E4F),
        secondaryColor: const Color(0xFF4A148C),
        accentColor: const Color(0xFFF48FB1),
        iconData: Symbols.health_and_safety_rounded,
        subtitle: 'Apple Beetroot Carrot Detox',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('carrot')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFFF7043),
        secondaryColor: const Color(0xFFD84315),
        accentColor: const Color(0xFFFFCCBC),
        iconData: Symbols.nutrition_rounded,
        subtitle: 'Fresh Vitalizing Carrot Juice',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('apple')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFE53935),
        secondaryColor: const Color(0xFFB71C1C),
        accentColor: const Color(0xFFFFCDD2),
        iconData: Symbols.nutrition_rounded,
        subtitle: 'Crisp Red Apple Juice',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('watermelon')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFE91E63),
        secondaryColor: const Color(0xFFC2185B),
        accentColor: const Color(0xFFFF80AB),
        iconData: Symbols.water_full_rounded,
        subtitle: 'Fresh Watermelon Juice',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('pineapple')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFFFD600),
        secondaryColor: const Color(0xFFFFAB00),
        accentColor: const Color(0xFFFFF9C4),
        iconData: Symbols.eco_rounded,
        subtitle: 'Tropical Pineapple Juice',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('musk melon') ||
        name.contains('muskmelon') ||
        name.contains('melon')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFFFB74D),
        secondaryColor: const Color(0xFFE65100),
        accentColor: const Color(0xFFFFE0B2),
        iconData: Symbols.eco_rounded,
        subtitle: 'Sweet Musk Melon Cooler',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('saththukudi') ||
        name.contains('mosambi') ||
        name.contains('sweet lime')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFFDD835),
        secondaryColor: const Color(0xFFF57F17),
        accentColor: const Color(0xFFFFF9C4),
        iconData: Symbols.nutrition_rounded,
        subtitle: 'Fresh Saththukudi Juice',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('lemon') ||
        name.contains('lime') ||
        name.contains('soda') ||
        name.contains('mint') ||
        name.contains('mojito')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFCDDC39),
        secondaryColor: const Color(0xFF827717),
        accentColor: const Color(0xFFF0F4C3),
        iconData: Symbols.nutrition_rounded,
        subtitle: 'Zesty Lime & Mint Cooler',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('butter fruit') ||
        name.contains('buttur') ||
        name.contains('avocado')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFF9CCC65),
        secondaryColor: const Color(0xFF558B2F),
        accentColor: const Color(0xFFDCEDC8),
        iconData: Symbols.eco_rounded,
        subtitle: 'Rich Avocado Butter Fruit Shake',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('custard apple') || name.contains('sitaphal')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFA5D6A7),
        secondaryColor: const Color(0xFF388E3C),
        accentColor: const Color(0xFFE8F5E9),
        iconData: Symbols.eco_rounded,
        subtitle: 'Creamy Custard Apple Juice',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('dates') ||
        name.contains('red banana') ||
        name.contains('redbanana')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFA1887F),
        secondaryColor: const Color(0xFF5D4037),
        accentColor: const Color(0xFFD7CCC8),
        iconData: Symbols.local_drink_rounded,
        subtitle: 'Rich Red Banana Dates Shake',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('iced tea') ||
        name.contains('ice tea') ||
        name.contains('lemon tea chilled')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFD48B38),
        secondaryColor: const Color(0xFF8D4F1E),
        accentColor: const Color(0xFFFFE082),
        iconData: Symbols.local_drink_rounded,
        subtitle: 'Refreshing Chilled Iced Tea',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('mango') ||
        name.contains('maaza') ||
        name.contains('frooti')) {
      return DrinkPresentation(
        format: DrinkFormat.coldJuice,
        primaryColor: const Color(0xFFFF9E1B),
        secondaryColor: const Color(0xFFE65100),
        accentColor: const Color(0xFFFFE082),
        iconData: Symbols.local_bar_rounded,
        subtitle: 'Chilled Alphonso Mango Juice',
        logoAssetPath: localAsset,
      );
    }

    // 3. Hot Drinks (Tea, Coffee, Boost, etc.)
    if (name.contains('tea') || name.contains('chai')) {
      return DrinkPresentation(
        format: DrinkFormat.hotBrew,
        primaryColor: const Color(0xFFC57A3A),
        secondaryColor: const Color(0xFF8D4F1E),
        accentColor: const Color(0xFFFFD59E),
        iconData: Symbols.emoji_food_beverage_rounded,
        subtitle: 'Freshly Brewed Hot Tea',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('coffee') ||
        name.contains('cappuccino') ||
        name.contains('espresso') ||
        name.contains('latte')) {
      return DrinkPresentation(
        format: DrinkFormat.hotBrew,
        primaryColor: const Color(0xFF4A2810),
        secondaryColor: const Color(0xFF2C1608),
        accentColor: const Color(0xFFD4A373),
        iconData: Symbols.coffee_rounded,
        subtitle: 'Rich Roasted Hot Coffee',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('boost') ||
        name.contains('horlicks') ||
        name.contains('chocolate') ||
        name.contains('bournvita')) {
      return DrinkPresentation(
        format: DrinkFormat.hotBrew,
        primaryColor: const Color(0xFF6B3E1E),
        secondaryColor: const Color(0xFF42220D),
        accentColor: const Color(0xFFFF9E80),
        iconData: Symbols.local_fire_department_rounded,
        subtitle: 'Warm Malt Energy Drink',
        logoAssetPath: localAsset,
      );
    }
    if (name.contains('green tea') || name.contains('herbal')) {
      return DrinkPresentation(
        format: DrinkFormat.hotBrew,
        primaryColor: const Color(0xFF689F38),
        secondaryColor: const Color(0xFF33691E),
        accentColor: const Color(0xFFC5E1A5),
        iconData: Symbols.eco_rounded,
        subtitle: 'Organic Herbal Green Tea',
        logoAssetPath: localAsset,
      );
    }

    // Default fallback for any other drink: Hot or Cold based on name
    if (name.contains('hot') || name.contains('warm')) {
      return DrinkPresentation(
        format: DrinkFormat.hotBrew,
        primaryColor: const Color(0xFF5D4037),
        secondaryColor: const Color(0xFF3E2723),
        accentColor: const Color(0xFFD7CCC8),
        iconData: Symbols.coffee_rounded,
        subtitle: 'Fresh Hot Beverage',
        logoAssetPath: localAsset,
      );
    }

    return DrinkPresentation(
      format: DrinkFormat.coldJuice,
      primaryColor: const Color(0xFFFF8A65),
      secondaryColor: const Color(0xFFD84315),
      accentColor: const Color(0xFFFFCCBC),
      iconData: Symbols.local_drink_rounded,
      subtitle: 'Chilled Fruit Drink',
      logoAssetPath: localAsset,
    );
  }
}
