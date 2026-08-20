import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snacks_app/core/design/app_theme.dart';
import 'package:snacks_app/core/design/glass.dart';
import 'package:snacks_app/core/widgets/app_buttons.dart';
import 'package:snacks_app/core/widgets/app_card.dart';
import 'package:snacks_app/core/widgets/category_scroller.dart';
import 'package:snacks_app/core/widgets/food_card.dart';
import 'package:snacks_app/core/widgets/glass_app_bar.dart';
import 'package:snacks_app/core/widgets/skeleton.dart';
import 'package:snacks_app/presentation/shell/glass_bottom_nav.dart';
import 'package:snacks_app/presentation/home/widgets/search_veg_row.dart';

Widget _host(ThemeData theme, Widget child) {
  return MaterialApp(
    theme: theme,
    // Reduce Motion on: also stops the skeleton shimmer's infinite timer so the
    // test harness doesn't fail on pending timers (and exercises the a11y path).
    builder: (context, body) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: body!,
    ),
    home: Scaffold(
      appBar: const GlassAppBar(title: 'Test'),
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  final showcase = Column(
    children: [
      const GlassSurface(child: SizedBox(height: 40, width: 100)),
      PrimaryButton(label: 'Primary', onPressed: () {}),
      const SecondaryButton(label: 'Secondary'),
      const GhostButton(label: 'Ghost'),
      const AppCard(child: Text('Card')),
      const StatusBanner(title: 'Status', subtitle: 'Subtitle'),
      const SnackCard(name: 'Samosa', isVeg: true, selected: false, servingSize: '2 Pcs'),
      const DrinkCard(name: 'Coffee', selected: true),
      const VegBadge(isVeg: false),
      CategoryScroller(
        items: const [
          CategoryItem(key: 'All', label: 'All', emoji: '🍽️'),
          CategoryItem(key: 'Drinks', label: 'Drinks', emoji: '🥤'),
        ],
        selectedKey: 'All',
        onSelected: (_) {},
      ),
      const FoodCardSkeleton(),
      SearchVegRow(
        query: '',
        onQueryChanged: (_) {},
        toggleLabel: 'VEG',
        toggleValue: false,
        onToggleChanged: (_) {},
      ),
      GlassBottomNav(
        currentIndex: 0,
        onTap: (_) {},
        destinations: const [
          NavDestinationData(
            icon: Icons.restaurant_outlined,
            selectedIcon: Icons.restaurant,
            label: 'Food',
          ),
          NavDestinationData(
            icon: Icons.local_cafe_outlined,
            selectedIcon: Icons.local_cafe,
            label: 'Drink',
          ),
          NavDestinationData(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: 'Orders',
          ),
        ],
      ),
    ],
  );

  testWidgets('design system renders in light mode', (tester) async {
    await tester.pumpWidget(_host(AppTheme.light, showcase));
    expect(tester.takeException(), isNull);
    expect(find.text('Samosa'), findsOneWidget);
    // Unselected cards show "ADD", selected cards show stepper (+/- and count)
    expect(find.text('ADD'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
  });

  testWidgets('design system renders in dark mode', (tester) async {
    await tester.pumpWidget(_host(AppTheme.dark, showcase));
    expect(tester.takeException(), isNull);
    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets('VegToggleSwitch renders VegBadge icon and responds to taps', (tester) async {
    bool toggled = false;
    await tester.pumpWidget(
      _host(
        AppTheme.light,
        StatefulBuilder(
          builder: (context, setState) {
            return SearchVegRow(
              query: '',
              onQueryChanged: (_) {},
              toggleLabel: 'VEG',
              toggleValue: toggled,
              onToggleChanged: (val) {
                setState(() => toggled = val);
              },
            );
          },
        ),
      ),
    );

    expect(find.text('VEG'), findsOneWidget);
    expect(find.byType(VegBadge), findsOneWidget);

    await tester.tap(find.byType(VegToggleSwitch));
    await tester.pumpAndSettle();

    expect(toggled, isTrue);
  });
}

