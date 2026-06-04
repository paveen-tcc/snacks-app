import 'package:flutter/material.dart';
import '../../core/di/locator.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/repositories/admin_repository.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  final Set<String> _revealedEmails = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await locator<AdminRepository>().getUsers();
      setState(() { _users = users; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleAdmin(Map<String, dynamic> user) async {
    final isAdmin = user['isAdmin'] as bool? ?? false;
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(isAdmin ? 'Remove Admin' : 'Make Admin'),
        content: Text(isAdmin
            ? 'Remove admin privileges from ${user['username']}?'
            : 'Grant admin privileges to ${user['username']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await locator<AdminRepository>().updateUserAdmin(user['id'] as String, !isAdmin);
        await _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update user')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: const GlassAppBar(title: 'Manage Users'),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: const [FoodListSkeleton(count: 5)],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.page),
              itemCount: _users.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) {
                final u = _users[i];
                final id = u['id'] as String;
                final isAdmin = u['isAdmin'] as bool? ?? false;
                final username = u['username'] as String;
                final email = u['email'] as String;
                final emailRevealed = _revealedEmails.contains(id);

                return AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: palette.brand.withValues(alpha: 0.14),
                        child: Text(
                          username.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: palette.brand,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() {
                            if (emailRevealed) {
                              _revealedEmails.remove(id);
                            } else {
                              _revealedEmails.add(id);
                            }
                          }),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      username,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.titleSmall,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Icon(
                                    emailRevealed
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                    size: 16,
                                    color: palette.textTertiary,
                                  ),
                                  if (isAdmin) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.info.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: AppRadii.rPill,
                                      ),
                                      child: Text(
                                        'Admin',
                                        style: context.text.labelSmall?.copyWith(
                                          color: palette.info,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              AnimatedSize(
                                duration: AppMotion.fast,
                                curve: AppMotion.standard,
                                alignment: Alignment.topLeft,
                                child: emailRevealed
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.text.bodySmall?.copyWith(
                                            color: palette.textSecondary,
                                          ),
                                        ),
                                      )
                                    : const SizedBox(width: double.infinity),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (isAdmin)
                        OutlinedButton(
                          onPressed: () => _toggleAdmin(u),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.danger,
                            side: BorderSide(
                              color: palette.danger.withValues(alpha: 0.4),
                            ),
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadii.rPill,
                            ),
                          ),
                          child: const Text('Remove Admin'),
                        )
                      else
                        FilledButton(
                          onPressed: () => _toggleAdmin(u),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                palette.brand.withValues(alpha: 0.14),
                            foregroundColor: palette.brand,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadii.rPill,
                            ),
                          ),
                          child: const Text('Make Admin'),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
