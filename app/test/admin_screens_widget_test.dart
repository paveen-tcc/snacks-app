import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/core/auth/microsoft_profile_photo_service.dart';
import 'package:snacks_app/core/design/app_theme.dart';
import 'package:snacks_app/core/di/locator.dart';
import 'package:snacks_app/core/network/api_client.dart';
import 'package:snacks_app/data/repositories/admin_repository.dart';
import 'package:snacks_app/presentation/admin/snacks_screen.dart';
import 'package:snacks_app/presentation/admin/users_screen.dart';

class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository({this.users = const [], this.snacks = const []})
    : super(ApiClient());

  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> snacks;

  @override
  Future<List<Map<String, dynamic>>> getUsers() async => users;

  @override
  Future<List<Map<String, dynamic>>> getAllSnacks() async => snacks;

  @override
  Future<void> updateUserAdmin(String id, bool isAdmin) async {}
}

Widget _host(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

Future<void> _register(_FakeAdminRepository repository) async {
  await locator.reset();
  locator.registerSingleton<AdminRepository>(repository);
  locator.registerSingleton<MicrosoftProfilePhotoService>(
    MicrosoftProfilePhotoService(acquireSession: () async => null),
  );
}

void main() {
  tearDown(() => locator.reset());

  testWidgets('Manage Users renders sorted two-row cards and filters admins', (
    tester,
  ) async {
    await _register(
      _FakeAdminRepository(
        users: const [
          {
            'id': 'bob',
            'username': 'Bob',
            'email': 'bob@example.com',
            'isAdmin': false,
          },
          {
            'id': 'alice',
            'username': 'Alice',
            'email': 'alice@example.com',
            'isAdmin': true,
          },
        ],
      ),
    );

    await tester.pumpWidget(_host(const AdminUsersScreen()));
    await tester.pumpAndSettle();

    expect(find.text('alice@example.com'), findsOneWidget);
    expect(find.text('bob@example.com'), findsOneWidget);
    expect(find.text('Remove admin'), findsOneWidget);
    expect(find.text('Make admin'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Alice')).dy,
      lessThan(tester.getTopLeft(find.text('Bob')).dy),
    );

    await tester.tap(find.byKey(const Key('manage-users-filter-admins')));
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsNothing);

    await tester.tap(find.byKey(const Key('manage-users-filter-all')));
    await tester.enterText(
      find.byKey(const Key('manage-users-search')),
      'bob@',
    );
    await tester.pump();
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Alice'), findsNothing);
  });

  testWidgets('Manage Snacks provides independent snack and drink controls', (
    tester,
  ) async {
    await _register(
      _FakeAdminRepository(
        snacks: const [
          {
            'id': 'pizza',
            'name': 'Margherita',
            'category': 'Pizza',
            'isActive': true,
            'isVeg': true,
            'sortOrder': 1,
          },
          {
            'id': 'tea',
            'name': 'Masala Tea',
            'category': 'Drinks',
            'isActive': true,
            'isVeg': true,
            'sortOrder': 2,
          },
          {
            'id': 'shake',
            'name': 'Mango Shake',
            'category': 'Drinks',
            'isActive': true,
            'isVeg': true,
            'sortOrder': 3,
          },
        ],
      ),
    );

    await tester.pumpWidget(_host(const AdminSnacksScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Search snacks'), findsOneWidget);
    expect(find.text('Add snack'), findsOneWidget);
    expect(find.text('Pizza'), findsWidgets);

    await tester.enterText(find.byKey(const Key('manage-menu-search')), 'mar');
    await tester.pump();
    expect(find.text('Margherita'), findsOneWidget);

    await tester.tap(find.byKey(const Key('manage-menu-tab-drinks')));
    await tester.pumpAndSettle();
    expect(find.text('Search drinks'), findsOneWidget);
    expect(find.text('Add drink'), findsOneWidget);
    expect(find.text('Cold Brews'), findsWidgets);
    expect(find.text('Hot Brews'), findsWidgets);
    expect(find.text('Tins'), findsWidgets);

    await tester.enterText(find.byKey(const Key('manage-menu-search')), 'tea');
    await tester.pump();
    expect(find.text('Masala Tea'), findsOneWidget);
    expect(find.text('Mango Shake'), findsNothing);

    await tester.tap(find.byKey(const Key('manage-menu-tab-snacks')));
    await tester.pumpAndSettle();
    expect(find.text('Nothing matches “mar”.'), findsNothing);
    expect(find.text('Margherita'), findsOneWidget);
  });
}
