import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/core/design/app_theme.dart';
import 'package:snacks_app/data/models/budget_models.dart';
import 'package:snacks_app/presentation/admin/budget_screen.dart';

void main() {
  Future<void> pumpBudget(
    WidgetTester tester, {
    required BudgetDayLoader loadDay,
    required BudgetRangeLoader loadRange,
    BudgetItemAdder? addItem,
    BudgetItemUpdater? updateItem,
    BudgetItemRemover? removeItem,
    DateTime? initialDate,
  }) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BudgetScreen(
          isActive: true,
          initialDate: initialDate ?? DateTime(2026, 8, 12),
          loadDay: loadDay,
          loadRange: loadRange,
          addItem: addItem,
          updateItem: updateItem,
          removeItem: removeItem,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('switches All Snacks Drinks without changing totals source', (
    tester,
  ) async {
    const day = BudgetDay(
      date: '2026-08-12',
      totals: BudgetTotals(total: 300, snacks: 220, drinks: 80),
      items: [
        BudgetLine(
          id: 'snack-1',
          date: '2026-08-12',
          name: 'Samosa',
          itemType: BudgetItemType.snack,
          quantity: 2,
          unitPriceRupees: 110,
          lineTotalRupees: 220,
          isEdited: false,
          isManual: false,
        ),
        BudgetLine(
          id: 'drink-1',
          date: '2026-08-12',
          name: 'Coffee',
          itemType: BudgetItemType.drink,
          quantity: 2,
          unitPriceRupees: 40,
          lineTotalRupees: 80,
          isEdited: false,
          isManual: false,
        ),
      ],
    );

    await pumpBudget(
      tester,
      loadDay: (_) async => day,
      loadRange: ({required start, required end}) async =>
          BudgetRange(start: start, end: end, totals: BudgetTotals.zero),
    );

    expect(find.text('₹300'), findsOneWidget);
    expect(find.text('Samosa'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);

    await tester.tap(find.byKey(const Key('budget-filter-snacks')));
    await tester.pumpAndSettle();

    expect(find.text('₹300'), findsOneWidget);
    expect(find.text('Samosa'), findsOneWidget);
    expect(find.text('Coffee'), findsNothing);

    await tester.tap(find.byKey(const Key('budget-filter-drinks')));
    await tester.pumpAndSettle();

    expect(find.text('₹300'), findsOneWidget);
    expect(find.text('Samosa'), findsNothing);
    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets('renders read-only purchase line items with percentage breakdown', (
    tester,
  ) async {
    const day = BudgetDay(
      date: '2026-08-12',
      totals: BudgetTotals(total: 200, snacks: 150, drinks: 50),
      items: [
        BudgetLine(
          id: 'line-1',
          date: '2026-08-12',
          name: 'Paneer Roll',
          itemType: BudgetItemType.snack,
          quantity: 3,
          unitPriceRupees: 50,
          lineTotalRupees: 150,
          isEdited: false,
          isManual: false,
        ),
      ],
    );

    await pumpBudget(
      tester,
      loadDay: (_) async => day,
      loadRange: ({required start, required end}) async =>
          BudgetRange(start: start, end: end, totals: BudgetTotals.zero),
    );

    expect(find.text('Paneer Roll'), findsOneWidget);
    expect(find.text('3 × ₹50'), findsOneWidget);
    expect(find.text('₹150'), findsOneWidget);
    expect(find.text('75% of day'), findsOneWidget);
    expect(find.text('Orders and item mappings are managed directly in Day Summary.'), findsOneWidget);
  });

  testWidgets('week day tap opens the selected day editor', (tester) async {
    final loadedDates = <String>[];
    String? rangeStart;
    String? rangeEnd;

    await pumpBudget(
      tester,
      loadDay: (date) async {
        loadedDates.add(date);
        return BudgetDay(
          date: date,
          totals: const BudgetTotals(total: 75, snacks: 75, drinks: 0),
          items: [
            BudgetLine(
              id: 'line-$date',
              date: date,
              name: 'Selected-day snack',
              itemType: BudgetItemType.snack,
              quantity: 1,
              unitPriceRupees: 75,
              lineTotalRupees: 75,
              isEdited: false,
              isManual: false,
            ),
          ],
        );
      },
      loadRange: ({required start, required end}) async {
        rangeStart = start;
        rangeEnd = end;
        return BudgetRange(
          start: start,
          end: end,
          totals: const BudgetTotals(total: 120, snacks: 120, drinks: 0),
          days: const [
            BudgetDay(
              date: '2026-08-11',
              totals: BudgetTotals(total: 120, snacks: 120, drinks: 0),
            ),
          ],
        );
      },
    );

    await tester.tap(find.byKey(const Key('budget-period-week')));
    await tester.pumpAndSettle();

    expect(rangeStart, '2026-08-10');
    expect(rangeEnd, '2026-08-16');
    await tester.tap(find.byKey(const Key('budget-day-2026-08-11')));
    await tester.pumpAndSettle();

    expect(loadedDates, contains('2026-08-11'));
    expect(find.text('Selected-day snack'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
  });

  testWidgets('renders Daily Spend Trend chart and Top Cost Drivers in Range view', (
    tester,
  ) async {
    await pumpBudget(
      tester,
      loadDay: (date) async => BudgetDay(date: date, totals: BudgetTotals.zero),
      loadRange: ({required start, required end}) async {
        final count = (start == '2026-08-10') ? 7 : 31;
        return BudgetRange(
          start: start,
          end: end,
          totals: const BudgetTotals(total: 500, snacks: 350, drinks: 150),
          days: List.generate(
            count,
            (i) => BudgetDay(
              date: '2026-08-${(i + 1).toString().padLeft(2, '0')}',
              totals: const BudgetTotals(total: 100, snacks: 70, drinks: 30),
            ),
          ),
          items: const [
            BudgetItemTotal(
              name: 'Chicken Pizza',
              itemType: BudgetItemType.snack,
              quantity: 5,
              totalRupees: 300,
            ),
            BudgetItemTotal(
              name: 'Cold Coffee',
              itemType: BudgetItemType.drink,
              quantity: 4,
              totalRupees: 200,
            ),
          ],
        );
      },
    );

    await tester.tap(find.byKey(const Key('budget-period-week')));
    await tester.pumpAndSettle();

    expect(find.text('Daily Spend Trend'), findsOneWidget);
    expect(find.text('Top Cost Drivers'), findsOneWidget);
    expect(find.text('Chicken Pizza'), findsOneWidget);
    expect(find.text('Cold Coffee'), findsOneWidget);

    await tester.tap(find.byKey(const Key('budget-period-month')));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Spend Trend'), findsOneWidget);
  });

  testWidgets('launch week clamps its range to the reporting start date', (
    tester,
  ) async {
    final ranges = <(String, String)>[];

    await pumpBudget(
      tester,
      initialDate: DateTime(2026, 8, 1),
      loadDay: (date) async => BudgetDay(date: date, totals: BudgetTotals.zero),
      loadRange: ({required start, required end}) async {
        ranges.add((start, end));
        return BudgetRange(start: start, end: end, totals: BudgetTotals.zero);
      },
    );

    await tester.tap(find.byKey(const Key('budget-period-week')));
    await tester.pumpAndSettle();

    expect(ranges, [('2026-08-01', '2026-08-02')]);
  });

  testWidgets('previous navigation never requests before reporting start', (
    tester,
  ) async {
    final requestedDays = <String>[];
    final requestedRanges = <(String, String)>[];

    await pumpBudget(
      tester,
      initialDate: DateTime(2026, 8, 1),
      loadDay: (date) async {
        requestedDays.add(date);
        return BudgetDay(date: date, totals: BudgetTotals.zero);
      },
      loadRange: ({required start, required end}) async {
        requestedRanges.add((start, end));
        return BudgetRange(start: start, end: end, totals: BudgetTotals.zero);
      },
    );

    final previousFinder = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Previous period',
    );
    IconButton previousButton() => tester.widget<IconButton>(previousFinder);

    expect(previousButton().onPressed, isNull);
    expect(requestedDays, ['2026-08-01']);

    await tester.tap(find.byKey(const Key('budget-period-week')));
    await tester.pumpAndSettle();
    expect(previousButton().onPressed, isNull);
    expect(requestedRanges, [('2026-08-01', '2026-08-02')]);

    await tester.tap(find.byKey(const Key('budget-period-month')));
    await tester.pumpAndSettle();
    expect(previousButton().onPressed, isNull);
    expect(requestedRanges.last, ('2026-08-01', '2026-08-31'));
  });

  testWidgets('failed refresh retains the previously loaded budget data', (
    tester,
  ) async {
    var loads = 0;
    await pumpBudget(
      tester,
      loadDay: (date) async {
        loads++;
        if (loads > 1) throw Exception('offline');
        return const BudgetDay(
          date: '2026-08-12',
          totals: BudgetTotals(total: 40, snacks: 40, drinks: 0),
          items: [
            BudgetLine(
              id: 'line-1',
              date: '2026-08-12',
              name: 'Retained Samosa',
              itemType: BudgetItemType.snack,
              quantity: 1,
              unitPriceRupees: 40,
              lineTotalRupees: 40,
              isEdited: false,
              isManual: false,
            ),
          ],
        );
      },
      loadRange: ({required start, required end}) async =>
          BudgetRange(start: start, end: end, totals: BudgetTotals.zero),
    );

    await tester.tap(find.byTooltip('Refresh budget'));
    await tester.pumpAndSettle();

    expect(loads, 2);
    expect(find.text('Retained Samosa'), findsOneWidget);
    expect(find.text('₹40'), findsWidgets);
    expect(
      find.text('Could not load budget. Pull down to retry.'),
      findsOneWidget,
    );
  });

  testWidgets('People Spend view renders ranking, filters, search, and opens detail sheet', (
    tester,
  ) async {
    const alice = UserSpending(
      userId: 'user-alice',
      username: 'Alice Wonderland',
      email: 'alice@example.com',
      totalSpendRupees: 125,
      totalOrdersCount: 2,
      snackSpendRupees: 85,
      drinkSpendRupees: 40,
      items: [
        UserBudgetItem(
          snackId: 'snack-pizza',
          name: 'Smiley Veg Pizza',
          itemType: BudgetItemType.snack,
          quantity: 1,
          unitPriceRupees: 85,
          totalRupees: 85,
        ),
        UserBudgetItem(
          snackId: 'snack-coffee',
          name: 'Cold coffee',
          itemType: BudgetItemType.drink,
          quantity: 1,
          unitPriceRupees: 40,
          totalRupees: 40,
        ),
      ],
    );

    const bob = UserSpending(
      userId: 'user-bob',
      username: 'Bob Builder',
      email: 'bob@example.com',
      totalSpendRupees: 30,
      totalOrdersCount: 2,
      snackSpendRupees: 0,
      drinkSpendRupees: 30,
      items: [
        UserBudgetItem(
          snackId: 'snack-chai',
          name: 'Masala Tea',
          itemType: BudgetItemType.drink,
          quantity: 2,
          unitPriceRupees: 15,
          totalRupees: 30,
        ),
      ],
    );

    const day = BudgetDay(
      date: '2026-08-12',
      totals: BudgetTotals(total: 155, snacks: 85, drinks: 70),
      items: [],
      userSpendings: [alice, bob],
    );

    await pumpBudget(
      tester,
      loadDay: (_) async => day,
      loadRange: ({required start, required end}) async =>
          BudgetRange(start: start, end: end, totals: BudgetTotals.zero),
    );

    // Switch to People Spend view
    await tester.tap(find.byKey(const Key('budget-view-people')));
    await tester.pumpAndSettle();

    // Verify stats & rankings
    expect(find.text('Active spenders'), findsOneWidget);
    expect(find.text('2 people'), findsOneWidget);
    expect(find.text('Alice Wonderland'), findsOneWidget);
    expect(find.text('Bob Builder'), findsOneWidget);
    expect(find.text('₹125'), findsOneWidget);
    expect(find.text('₹30'), findsOneWidget);

    // Filter by Snacks only: Bob (₹0 snack spend) should disappear from the list
    await tester.tap(find.byKey(const Key('budget-filter-snacks')));
    await tester.pumpAndSettle();

    expect(find.text('Alice Wonderland'), findsOneWidget);
    expect(find.text('Bob Builder'), findsNothing);

    // Filter back to All
    await tester.tap(find.byKey(const Key('budget-filter-all')));
    await tester.pumpAndSettle();

    expect(find.text('Alice Wonderland'), findsOneWidget);
    expect(find.text('Bob Builder'), findsOneWidget);

    // Search for Bob
    await tester.enterText(find.byKey(const Key('budget-search')), 'bob');
    await tester.pumpAndSettle();

    expect(find.text('Bob Builder'), findsOneWidget);
    expect(find.text('Alice Wonderland'), findsNothing);

    // Clear search
    await tester.enterText(find.byKey(const Key('budget-search')), '');
    await tester.pumpAndSettle();

    // Tap Alice to open details bottom sheet
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('user-spending-user-alice')));
    await tester.pumpAndSettle();

    expect(find.text('Total Spend'), findsOneWidget);
    expect(find.text('Smiley Veg Pizza'), findsOneWidget);
    expect(find.text('Cold coffee'), findsOneWidget);
    expect(find.text('1 × ₹85'), findsOneWidget);
  });
}
