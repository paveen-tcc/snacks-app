import 'dart:async';

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

  testWidgets('day editor validates and saves a whole-rupee custom item', (
    tester,
  ) async {
    Map<String, dynamic>? saved;
    var dayLoads = 0;

    await pumpBudget(
      tester,
      loadDay: (date) async {
        dayLoads++;
        return BudgetDay(date: date, totals: BudgetTotals.zero);
      },
      loadRange: ({required start, required end}) async =>
          BudgetRange(start: start, end: end, totals: BudgetTotals.zero),
      addItem: (date, data) async {
        expect(date, '2026-08-12');
        saved = data;
      },
    );

    await tester.tap(find.byKey(const Key('budget-add-item')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('budget-item-name')),
      'Office fruit',
    );
    await tester.enterText(find.byKey(const Key('budget-item-quantity')), '2');
    await tester.enterText(find.byKey(const Key('budget-item-price')), '12.5');
    await tester.ensureVisible(find.byKey(const Key('budget-save-item')));
    await tester.tap(find.byKey(const Key('budget-save-item')));
    await tester.pump();

    expect(find.text('Enter a whole-rupee price (0 or more)'), findsOneWidget);
    expect(saved, isNull);

    await tester.enterText(find.byKey(const Key('budget-item-price')), '45');
    await tester.ensureVisible(find.byKey(const Key('budget-save-item')));
    await tester.tap(find.byKey(const Key('budget-save-item')));
    await tester.pumpAndSettle();

    expect(saved, {
      'name': 'Office fruit',
      'itemType': 'snack',
      'quantity': 2,
      'unitPriceRupees': 45,
    });
    expect(dayLoads, 2);
    expect(find.text('Item added'), findsOneWidget);
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

  testWidgets('calendar picker keeps the stable reporting start reachable', (
    tester,
  ) async {
    await pumpBudget(
      tester,
      initialDate: DateTime(2027, 3, 15),
      loadDay: (date) async => BudgetDay(date: date, totals: BudgetTotals.zero),
      loadRange: ({required start, required end}) async =>
          BudgetRange(start: start, end: end, totals: BudgetTotals.zero),
    );

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();

    final dialog = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(dialog.firstDate, DateTime(2026, 8, 1));
  });

  testWidgets('day editor disables every input while saving', (tester) async {
    final saveCompleter = Completer<void>();

    await pumpBudget(
      tester,
      loadDay: (date) async => BudgetDay(date: date, totals: BudgetTotals.zero),
      loadRange: ({required start, required end}) async =>
          BudgetRange(start: start, end: end, totals: BudgetTotals.zero),
      addItem: (_, _) => saveCompleter.future,
    );

    await tester.tap(find.byKey(const Key('budget-add-item')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('budget-item-name')), 'Fruit');
    await tester.enterText(find.byKey(const Key('budget-item-quantity')), '2');
    await tester.enterText(find.byKey(const Key('budget-item-price')), '50');
    await tester.ensureVisible(find.byKey(const Key('budget-save-item')));
    await tester.tap(find.byKey(const Key('budget-save-item')));
    await tester.pump();

    TextFormField field(Key key) =>
        tester.widget<TextFormField>(find.byKey(key));

    expect(field(const Key('budget-item-name')).enabled, isFalse);
    expect(field(const Key('budget-item-quantity')).enabled, isFalse);
    expect(field(const Key('budget-item-price')).enabled, isFalse);

    saveCompleter.complete();
    await tester.pumpAndSettle();
  });
}
