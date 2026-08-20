import 'package:flutter_test/flutter_test.dart';
import 'package:snacks_app/presentation/admin/users_screen.dart';

void main() {
  final users = <Map<String, dynamic>>[
    {
      'id': '3',
      'username': 'zoe',
      'email': 'zoe@example.com',
      'isAdmin': false,
    },
    {
      'id': '2',
      'username': 'Alice',
      'email': 'second@example.com',
      'isAdmin': true,
    },
    {
      'id': '1',
      'username': 'alice',
      'email': 'first@example.com',
      'isAdmin': false,
    },
  ];

  test('sorts names A-Z and uses email as a stable tie-breaker', () {
    final result = filterAndSortAdminUsers(users, query: '', adminsOnly: false);

    expect(result.map((user) => user['id']), ['1', '2', '3']);
  });

  test('searches names and emails case-insensitively', () {
    expect(
      filterAndSortAdminUsers(users, query: 'EXAMPLE.COM', adminsOnly: false),
      hasLength(3),
    );
    expect(
      filterAndSortAdminUsers(
        users,
        query: 'ZoE',
        adminsOnly: false,
      ).single['id'],
      '3',
    );
  });

  test('admin filter composes with search', () {
    final result = filterAndSortAdminUsers(
      users,
      query: 'alice',
      adminsOnly: true,
    );

    expect(result.map((user) => user['id']), ['2']);
  });
}
