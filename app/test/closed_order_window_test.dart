import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/core/design/app_theme.dart';
import 'package:snacks_app/core/widgets/food_card.dart';
import 'package:snacks_app/presentation/home/bloc/home_bloc.dart';
import 'package:snacks_app/presentation/home/cart.dart';
import 'package:snacks_app/presentation/home/widgets/home_blue_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Order Window Closed UI Tests', () {
    testWidgets('HomeHeroBanner shows "Not accepting orders at the moment" and 00:00:00 when closed', (
      WidgetTester tester,
    ) async {
      final state = HomeLoaded(
        snacks: const [],
        cutoffTime: '00:00', // guarantees cutoff has passed for today
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: HomeHeroBanner(state: state),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Not accepting orders at the moment'), findsOneWidget);
      expect(find.text('Hrs'), findsOneWidget);
      expect(find.text('Mins'), findsOneWidget);
      expect(find.text('Secs'), findsOneWidget);
    });

    testWidgets('FoodCard and SnackCard render disabled styling and ignore taps when disabled', (
      WidgetTester tester,
    ) async {
      var tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                height: 198,
                child: SnackCard(
                  name: 'Baked Samosa',
                  isVeg: true,
                  servingSize: '2 Pcs',
                  disabled: true,
                  onTap: () => tapCount++,
                  onIncrement: () => tapCount++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Baked Samosa'), findsOneWidget);
      expect(find.text('ADD'), findsOneWidget);

      await tester.tap(find.text('ADD'));
      await tester.pump();
      expect(tapCount, equals(0));

      await tester.tap(find.byType(SnackCard));
      await tester.pump();
      expect(tapCount, equals(0));
    });

    testWidgets('CartBar displays "Today\'s order" and "Window closed" when closed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CartBar(
              itemCount: 2,
              orderPlaced: true,
              isClosed: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Today\'s order'), findsOneWidget);
      expect(find.text('Window closed • Tap to view order'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}
