import 'package:flutter/material.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/di/locator.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/microsoft_avatar.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/repositories/admin_repository.dart';

@visibleForTesting
List<Map<String, dynamic>> filterAndSortAdminUsers(
  Iterable<Map<String, dynamic>> users, {
  required String query,
  required bool adminsOnly,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final result = users.where((user) {
    final isAdmin = user['isAdmin'] as bool? ?? false;
    if (adminsOnly && !isAdmin) return false;
    if (normalizedQuery.isEmpty) return true;
    final name = (user['username'] as String? ?? '').toLowerCase();
    final email = (user['email'] as String? ?? '').toLowerCase();
    return name.contains(normalizedQuery) || email.contains(normalizedQuery);
  }).toList();

  result.sort((a, b) {
    final aName = (a['username'] as String? ?? '').trim().toLowerCase();
    final bName = (b['username'] as String? ?? '').trim().toLowerCase();
    final nameComparison = aName.compareTo(bName);
    if (nameComparison != 0) return nameComparison;
    final aEmail = (a['email'] as String? ?? '').trim().toLowerCase();
    final bEmail = (b['email'] as String? ?? '').trim().toLowerCase();
    return aEmail.compareTo(bEmail);
  });
  return result;
}

enum _UserFilter { all, admins }

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  String _query = '';
  _UserFilter _filter = _UserFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final users = await locator<AdminRepository>().getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAdmin(Map<String, dynamic> user) async {
    final isAdmin = user['isAdmin'] as bool? ?? false;
    final username = user['username'] as String? ?? 'this user';
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(isAdmin ? 'Remove Admin' : 'Make Admin'),
        content: Text(
          isAdmin
              ? 'Remove admin privileges from $username?'
              : 'Grant admin privileges to $username?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await locator<AdminRepository>().updateUserAdmin(
        user['id'] as String,
        !isAdmin,
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update user')));
      }
    }
  }

  List<Map<String, dynamic>> get _visibleUsers => filterAndSortAdminUsers(
    _users,
    query: _query,
    adminsOnly: _filter == _UserFilter.admins,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Manage Users'),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: const [FoodListSkeleton(count: 5)],
            )
          : Column(
              children: [
                _buildControls(context),
                Expanded(child: _buildUserList(context)),
              ],
            ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 46,
            child: TextField(
              key: const Key('manage-users-search'),
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search_rounded, size: 21),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear_rounded, size: 19),
                      ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _buildFilterPill(
                context,
                key: const Key('manage-users-filter-all'),
                label: 'All users',
                selected: _filter == _UserFilter.all,
                onTap: () => setState(() => _filter = _UserFilter.all),
              ),
              _buildFilterPill(
                context,
                key: const Key('manage-users-filter-admins'),
                label: 'Admins',
                selected: _filter == _UserFilter.admins,
                onTap: () => setState(() => _filter = _UserFilter.admins),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(
    BuildContext context, {
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? palette.brand.withValues(alpha: 0.14)
              : palette.surface,
          borderRadius: AppRadii.rPill,
          border: Border.all(
            color: selected
                ? palette.brand.withValues(alpha: 0.40)
                : palette.border,
          ),
          boxShadow: selected ? context.shadows.sm : null,
        ),
        child: Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: selected ? palette.brand : palette.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context) {
    final visibleUsers = _visibleUsers;
    if (_users.isEmpty) {
      return const _UserEmptyState(
        icon: Icons.group_outlined,
        title: 'No users yet',
        subtitle: 'Users will appear after their first sign-in.',
      );
    }
    if (visibleUsers.isEmpty) {
      return _UserEmptyState(
        icon: Icons.person_search_rounded,
        title: 'No matching users',
        subtitle: _filter == _UserFilter.admins && _query.trim().isEmpty
            ? 'There are no administrators to show.'
            : 'Try another name, email, or filter.',
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.x5,
      ),
      itemCount: visibleUsers.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _buildUserCard(visibleUsers[index]),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final palette = context.palette;
    final isAdmin = user['isAdmin'] as bool? ?? false;
    final username = user['username'] as String? ?? '';
    final email = user['email'] as String? ?? '';

    return AppCard(
      key: ValueKey('manage-user-${user['id']}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          MicrosoftAvatar(
            displayName: username,
            userPrincipalName: email,
            radius: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username.isEmpty ? 'Unnamed user' : username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: palette.brand.withValues(alpha: 0.12),
                          borderRadius: AppRadii.rPill,
                        ),
                        child: Text(
                          'Admin',
                          style: context.text.labelSmall?.copyWith(
                            color: palette.brand,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (isAdmin)
            OutlinedButton(
              key: ValueKey('remove-admin-${user['id']}'),
              onPressed: () => _toggleAdmin(user),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 32),
                foregroundColor: palette.danger,
                side: BorderSide(
                  color: palette.danger.withValues(alpha: 0.40),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.rPill,
                ),
              ),
              child: const Text(
                'Remove admin',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else
            FilledButton(
              key: ValueKey('make-admin-${user['id']}'),
              onPressed: () => _toggleAdmin(user),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 32),
                backgroundColor: palette.brand.withValues(alpha: 0.12),
                foregroundColor: palette.brand,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.rPill,
                ),
              ),
              child: const Text(
                'Make admin',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserEmptyState extends StatelessWidget {
  const _UserEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: context.palette.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
