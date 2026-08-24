import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/core/design/app_theme.dart';
import 'package:snacks_app/core/di/locator.dart';
import 'package:snacks_app/core/network/api_client.dart';
import 'package:snacks_app/core/widgets/app_buttons.dart';
import 'package:snacks_app/data/repositories/admin_repository.dart';
import 'package:snacks_app/presentation/admin/summary_screen.dart';

class _MockAdminRepository extends AdminRepository {
  _MockAdminRepository() : super(ApiClient());

  Map<String, dynamic> summaryData = {
    'date': '2026-08-23',
    'orders': [
      {
        'snackId': 'snack-1',
        'snackName': 'Veg Samosa',
        'snackEmoji': '🥟',
        'count': 2,
        'priceRupees': 20,
        'orderedBy': ['Alice', 'Bob'],
        'users': [
          {'id': 'u1', 'username': 'Alice'},
          {'id': 'u2', 'username': 'Bob'},
        ],
      },
    ],
    'drinks': [
      {
        'drinkId': 'drink-1',
        'drinkName': 'Masala Chai',
        'drinkEmoji': '☕',
        'count': 1,
        'priceRupees': 15,
        'votedBy': ['Alice'],
        'users': [
          {'id': 'u1', 'username': 'Alice'},
        ],
      },
    ],
    'totalOrders': 2,
    'notOrdered': ['Charlie'],
    'notOrderedUsers': [
      {'id': 'u3', 'username': 'Charlie'},
    ],
  };

  List<Map<String, dynamic>> catalog = [
    {
      'id': 'snack-1',
      'name': 'Veg Samosa',
      'emoji': '🥟',
      'category': 'Snacks',
      'priceRupees': 20,
    },
    {
      'id': 'snack-2',
      'name': 'Paneer Roll',
      'emoji': '🌯',
      'category': 'Snacks',
      'priceRupees': 45,
    },
    {
      'id': 'drink-1',
      'name': 'Masala Chai',
      'emoji': '☕',
      'category': 'Drinks',
      'priceRupees': 15,
    },
  ];

  String? lastReassignedToId;
  String? lastUpdatedUserId;
  List<String>? lastUpdatedSnackIds;

  @override
  Future<Map<String, dynamic>> getSummary({String? date}) async {
    return summaryData;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllSnacks() async {
    return catalog;
  }

  @override
  Future<void> reassignSummaryItem({
    required String date,
    required String toSnackId,
    String? fromSnackId,
    String? fromSnackName,
    bool? isSugarFree,
    List<String>? userIds,
  }) async {
    lastReassignedToId = toSnackId;
  }

  @override
  Future<void> updateUserOrderAdmin({
    required String userId,
    required String date,
    required List<String> snackIds,
    List<String>? sugarFreeSnackIds,
  }) async {
    lastUpdatedUserId = userId;
    lastUpdatedSnackIds = snackIds;
  }

  @override
  Future<List<Map<String, dynamic>>> getUsers() async {
    return [
      {'id': 'u1', 'username': 'Alice'},
      {'id': 'u2', 'username': 'Bob'},
      {'id': 'u3', 'username': 'Charlie'},
    ];
  }

  @override
  Future<void> deleteUserOrderAdmin({
    required String userId,
    required String date,
    String? snackId,
    String? orderId,
  }) async {}
}

Future<void> _register(_MockAdminRepository repository) async {
  await locator.reset();
  locator.registerSingleton<AdminRepository>(repository);
}

void main() {
  late _MockAdminRepository mockRepo;

  setUp(() async {
    mockRepo = _MockAdminRepository();
    await _register(mockRepo);
  });

  tearDown(() => locator.reset());

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SummaryScreen(
          isTab: true,
          isActive: true,
          initialDate: DateTime(2026, 8, 23),
        ),
      ),
    );
  }

  testWidgets('SummaryScreen renders date navigator, not-ordered, snacks and drinks',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Veg Samosa'), findsOneWidget);
    expect(find.text('Masala Chai'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);
    expect(find.text('Alice'), findsNWidgets(2)); // in snack and drink
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('Tapping replace item button opens reassign sheet and can select replacement',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap replace button for Veg Samosa
    final replaceButton = find.byTooltip('Replace or reassign this item').first;
    await tester.tap(replaceButton);
    await tester.pumpAndSettle();

    expect(find.text('Paneer Roll'), findsOneWidget);

    // Tap Paneer Roll
    await tester.tap(find.text('Paneer Roll'));
    await tester.pumpAndSettle();

    // Tap Replace Item CTA
    final replaceCta = find.widgetWithText(PrimaryButton, 'Replace Item');
    await tester.tap(replaceCta);
    await tester.pumpAndSettle();

    expect(mockRepo.lastReassignedToId, 'snack-2');
  });

  testWidgets('Tapping not-ordered user chip opens place order sheet',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap Charlie chip in Not Ordered section
    await tester.tap(find.text('Charlie'));
    await tester.pumpAndSettle();

    expect(find.text('Add Item: Charlie'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Pick Veg Samosa for Charlie
    await tester.tap(find.widgetWithText(ListTile, 'Veg Samosa'));
    await tester.pumpAndSettle();

    // Save order
    final saveCta = find.widgetWithText(PrimaryButton, 'Save Order');
    await tester.tap(saveCta);
    await tester.pumpAndSettle();

    expect(mockRepo.lastUpdatedUserId, 'u3');
    expect(mockRepo.lastUpdatedSnackIds, ['snack-1']);
  });

  testWidgets('Tapping ordered user chip opens edit order sheet',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap Bob under Veg Samosa
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Order: Bob'), findsOneWidget);

    // Pick Paneer Roll instead of Samosa
    await tester.tap(find.widgetWithText(ListTile, 'Paneer Roll'));
    await tester.pumpAndSettle();

    // Save order
    final saveCta = find.widgetWithText(PrimaryButton, 'Save Order');
    await tester.tap(saveCta);
    await tester.pumpAndSettle();

    expect(mockRepo.lastUpdatedUserId, 'u2');
    expect(mockRepo.lastUpdatedSnackIds, ['snack-2']);
  });

  testWidgets('Groups multiple orders by the same person into a single chip with count',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Modify summary data to have Alice order 3 Boiled Eggs
    mockRepo.summaryData = {
      'date': '2026-08-23',
      'orders': [
        {
          'snackId': 'snack-egg',
          'snackName': 'Boiled Egg',
          'snackEmoji': '🥚',
          'count': 3,
          'priceRupees': 15,
          'orderedBy': ['Alice', 'Alice', 'Alice'],
          'users': [
            {'id': 'u1', 'username': 'Alice'},
            {'id': 'u1', 'username': 'Alice'},
            {'id': 'u1', 'username': 'Alice'},
          ],
        },
      ],
      'drinks': [],
      'totalOrders': 3,
      'notOrdered': [],
      'notOrderedUsers': [],
    };

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Boiled Egg'), findsOneWidget);
    expect(find.text('Alice ×3'), findsOneWidget);
    // Ensure only 1 chip is shown rather than 3 duplicate chips
    expect(find.byType(ActionChip), findsOneWidget);
  });
}
