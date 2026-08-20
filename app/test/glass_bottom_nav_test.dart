import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snacks_app/core/design/app_theme.dart';
import 'package:snacks_app/presentation/shell/glass_bottom_nav.dart';

const _destinations = [
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
];

Widget _navHost(ValueChanged<int> onChanged, {int initialIndex = 0}) {
  var selectedIndex = initialIndex;
  return MaterialApp(
    theme: AppTheme.light,
    home: StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          bottomNavigationBar: GlassBottomNav(
            currentIndex: selectedIndex,
            onTap: (index) {
              setState(() => selectedIndex = index);
              onChanged(index);
            },
            destinations: _destinations,
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('indicator glides to a tapped destination', (tester) async {
    await tester.pumpWidget(_navHost((_) {}));

    final indicator = find.byKey(const ValueKey('bottom_nav_indicator'));
    final start = tester.getTopLeft(indicator).dx;

    await tester.tap(find.byKey(const ValueKey('bottom_nav_item_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final duringMotion = tester.getTopLeft(indicator).dx;
    expect(duringMotion, greaterThan(start));
    expect(
      find.descendant(of: indicator, matching: find.text('Drink')),
      findsOneWidget,
    );
    expect(
      tester.widget<Icon>(find.byKey(const ValueKey('active_icon_1'))).color,
      Colors.white,
    );

    await tester.pumpAndSettle();
    final atDestination = tester.getTopLeft(indicator).dx;
    expect(atDestination, greaterThan(duringMotion));
    expect(find.text('Drink'), findsOneWidget);
  });

  testWidgets('indicator follows a drag and selects the nearest destination', (
    tester,
  ) async {
    var selectedIndex = 0;
    await tester.pumpWidget(_navHost((index) => selectedIndex = index));

    final indicator = find.byKey(const ValueKey('bottom_nav_indicator'));
    final start = tester.getTopLeft(indicator).dx;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('bottom_nav_item_0'))),
    );
    // The first move wins the horizontal-drag gesture arena; the second one
    // exercises the continuous indicator tracking.
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(470, 0));
    await tester.pump();

    expect(tester.getTopLeft(indicator).dx, greaterThan(start));
    expect(selectedIndex, 0);
    expect(
      find.descendant(of: indicator, matching: find.text('Orders')),
      findsOneWidget,
    );

    await gesture.up();
    await tester.pumpAndSettle();

    expect(selectedIndex, 2);
    expect(find.text('Orders'), findsOneWidget);
  });
}
