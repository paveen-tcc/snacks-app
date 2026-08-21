import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/core/design/app_theme.dart';
import 'package:snacks_app/data/local/app_database.dart';
import 'package:snacks_app/presentation/home/widgets/dispenser/cold_fountain_dispenser.dart';
import 'package:snacks_app/presentation/home/widgets/dispenser/drink_carousel.dart';
import 'package:snacks_app/presentation/home/widgets/dispenser/drink_dispenser_models.dart';
import 'package:snacks_app/presentation/home/widgets/dispenser/hot_barista_dispenser.dart';
import 'package:snacks_app/presentation/home/widgets/dispenser/skeuomorphic_rocker_switch.dart';

void main() {
  group('DrinkPresentation Tests', () {
    test('DrinkPresentation.fromSnack correctly classifies Cans and GLB models', () {
      const redbull = LocalSnack(
        id: '1',
        name: 'Red Bull Energy Drink',
        category: 'Drinks',
        isVeg: true,
        isDefault: false,
        isActive: true,
        servingSize: '250ml',
        shareCount: 1,
        sortOrder: 0,
      );
      final p1 = DrinkPresentation.fromSnack(redbull);
      expect(p1.format, DrinkFormat.can);
      expect(p1.canBrand, 'REDBULL');
      expect(p1.model3dPath, 'assets/models/red_bull_can.glb');

      const monsterUltra = LocalSnack(
        id: '2',
        name: 'Monster Ultra Zero',
        category: 'Drinks',
        isVeg: true,
        isDefault: false,
        isActive: true,
        servingSize: '350ml',
        shareCount: 1,
        sortOrder: 1,
      );
      final p2 = DrinkPresentation.fromSnack(monsterUltra);
      expect(p2.format, DrinkFormat.can);
      expect(p2.canBrand, 'MONSTER');
      expect(p2.model3dPath, 'assets/models/monster_ultra_zero.glb');

      const monsterGreen = LocalSnack(
        id: '2b',
        name: 'Monster Energy Drink',
        category: 'Drinks',
        isVeg: true,
        isDefault: false,
        isActive: true,
        servingSize: '350ml',
        shareCount: 1,
        sortOrder: 1,
      );
      final p2b = DrinkPresentation.fromSnack(monsterGreen);
      expect(p2b.format, DrinkFormat.can);
      expect(p2b.canBrand, 'MONSTER');
      expect(p2b.model3dPath, 'assets/models/monster_green.glb');

      const dietCoke = LocalSnack(
        id: '3',
        name: 'Diet Coke Zero',
        category: 'Drinks',
        isVeg: true,
        isDefault: false,
        isActive: true,
        servingSize: '300ml',
        shareCount: 1,
        sortOrder: 2,
      );
      final p3 = DrinkPresentation.fromSnack(dietCoke);
      expect(p3.format, DrinkFormat.can);
      expect(p3.canBrand, 'COKE');
      expect(p3.model3dPath, 'assets/models/diet_coke_can.glb');

      const coke = LocalSnack(
        id: '4',
        name: 'Coca Cola Can',
        category: 'Drinks',
        isVeg: true,
        isDefault: false,
        isActive: true,
        servingSize: '300ml',
        shareCount: 1,
        sortOrder: 3,
      );
      final p4 = DrinkPresentation.fromSnack(coke);
      expect(p4.format, DrinkFormat.can);
      expect(p4.canBrand, 'COKE');
      expect(p4.model3dPath, 'assets/models/coke.glb');
    });

    test('DrinkPresentation.fromSnack correctly classifies Cold Juices and Hot Brews', () {
      const coldCoffee = LocalSnack(
        id: '5',
        name: 'Cold Coffee Frappe',
        category: 'Drinks',
        isVeg: true,
        isDefault: false,
        isActive: true,
        servingSize: '1 Glass',
        shareCount: 1,
        sortOrder: 4,
      );
      final p5 = DrinkPresentation.fromSnack(coldCoffee);
      expect(p5.format, DrinkFormat.coldJuice);

      const hotTea = LocalSnack(
        id: '6',
        name: 'Fresh Hot Masala Chai Tea',
        category: 'Drinks',
        isVeg: true,
        isDefault: false,
        isActive: true,
        servingSize: '1 Cup',
        shareCount: 1,
        sortOrder: 5,
      );
      final p6 = DrinkPresentation.fromSnack(hotTea);
      expect(p6.format, DrinkFormat.hotBrew);
    });
  });

  group('SkeuomorphicRockerSwitch Widget Tests', () {
    testWidgets('Renders sugar on state with label and toggles to 0 sugar on tap', (tester) async {
      bool isSugarFree = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: SkeuomorphicRockerSwitch(
                    isSugarFree: isSugarFree,
                    onChanged: (val) {
                      setState(() => isSugarFree = val);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify 'SUGAR' text is displayed
      expect(find.text('SUGAR'), findsOneWidget);

      // Tap the switch
      await tester.tap(find.byType(SkeuomorphicRockerSwitch));
      await tester.pumpAndSettle();

      // Verify toggled to Sugar-Free (0 SUGAR)
      expect(isSugarFree, true);
      expect(find.text('0 SUGAR'), findsOneWidget);
    });
  });

  group('ColdFountainDispenser Widget Tests', () {
    testWidgets('Renders drink buttons and handles drink selection', (tester) async {
      int selectedIdx = 0;
      bool sugarFree = false;

      const List<LocalSnack> drinks = [
        LocalSnack(
          id: '1',
          name: 'Mango Juice',
          category: 'Drinks',
          isVeg: true,
          isDefault: false,
          isActive: true,
          servingSize: '1 Glass',
          shareCount: 1,
          sortOrder: 0,
        ),
        LocalSnack(
          id: '2',
          name: 'Apple Juice',
          category: 'Drinks',
          isVeg: true,
          isDefault: false,
          isActive: true,
          servingSize: '1 Glass',
          shareCount: 1,
          sortOrder: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ColdFountainDispenser(
                  drinks: drinks,
                  selectedIndex: selectedIdx,
                  onDrinkSelected: (idx) => setState(() => selectedIdx = idx),
                  isSugarFree: sugarFree,
                  onSugarFreeChanged: (sf) => setState(() => sugarFree = sf),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('COLD BEVERAGE FOUNTAIN'), findsOneWidget);
      expect(find.text('Mango Juice'), findsOneWidget);
      expect(find.text('Apple Juice'), findsOneWidget);

      // Tap Apple Juice
      await tester.tap(find.text('Apple Juice'));
      await tester.pumpAndSettle();
      expect(selectedIdx, 1);
    });
  });

  group('HotBaristaDispenser Widget Tests', () {
    testWidgets('Renders barista brewer buttons and handles selection', (tester) async {
      int selectedIdx = 0;
      bool sugarFree = false;

      const List<LocalSnack> drinks = [
        LocalSnack(
          id: '1',
          name: 'Filter Coffee',
          category: 'Drinks',
          isVeg: true,
          isDefault: false,
          isActive: true,
          servingSize: '1 Cup',
          shareCount: 1,
          sortOrder: 0,
        ),
        LocalSnack(
          id: '2',
          name: 'Masala Chai',
          category: 'Drinks',
          isVeg: true,
          isDefault: false,
          isActive: true,
          servingSize: '1 Cup',
          shareCount: 1,
          sortOrder: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return HotBaristaDispenser(
                  drinks: drinks,
                  selectedIndex: selectedIdx,
                  onDrinkSelected: (idx) => setState(() => selectedIdx = idx),
                  isSugarFree: sugarFree,
                  onSugarFreeChanged: (sf) => setState(() => sugarFree = sf),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('SMART BARISTA BREWER'), findsOneWidget);
      expect(find.text('Filter Coffee'), findsOneWidget);
      expect(find.text('Masala Chai'), findsOneWidget);

      // Tap Masala Chai
      await tester.tap(find.text('Masala Chai'));
      await tester.pumpAndSettle();
      expect(selectedIdx, 1);
    });
  });

  group('DrinkCarousel Widget Tests', () {
    testWidgets('Renders drink items and triggers drink selection, increment, and decrement', (tester) async {
      int selectedIdx = 0;
      bool sugarFree = false;
      final List<String> selectedIds = ['1'];
      LocalSnack? incrementedDrink;
      LocalSnack? decrementedDrink;

      const List<LocalSnack> drinks = [
        LocalSnack(
          id: '1',
          name: 'Orange Juice',
          category: 'Drinks',
          isVeg: true,
          isDefault: false,
          isActive: true,
          servingSize: '1 Glass',
          shareCount: 1,
          sortOrder: 0,
        ),
        LocalSnack(
          id: '2',
          name: 'Watermelon Juice',
          category: 'Drinks',
          isVeg: true,
          isDefault: false,
          isActive: true,
          servingSize: '1 Glass',
          shareCount: 1,
          sortOrder: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DrinkCarousel(
                  drinks: drinks,
                  selectedIndex: selectedIdx,
                  onDrinkSelected: (idx) => setState(() => selectedIdx = idx),
                  isSugarFree: sugarFree,
                  onSugarFreeChanged: (sf) => setState(() => sugarFree = sf),
                  selectedSnackIds: selectedIds,
                  onIncrement: (d) {
                    incrementedDrink = d;
                    setState(() => selectedIds.add(d.id));
                  },
                  onDecrement: (d) {
                    decrementedDrink = d;
                    setState(() => selectedIds.remove(d.id));
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify drink titles are rendered below capsule icons
      expect(find.text('Orange Juice'), findsOneWidget);
      expect(find.text('Watermelon Juice'), findsOneWidget);

      // Tap on second drink capsule
      await tester.tap(find.text('Watermelon Juice'));
      await tester.pumpAndSettle();
      expect(selectedIdx, 1);

      // Tap ADD on selected drink
      await tester.tap(find.text('ADD'));
      await tester.pumpAndSettle();
      expect(incrementedDrink?.name, 'Watermelon Juice');

      // Tap remove
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(decrementedDrink?.name, 'Watermelon Juice');
    });
  });
}

