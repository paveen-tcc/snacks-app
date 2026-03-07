import 'package:flutter/material.dart';
import '../../core/di/locator.dart';
import '../../core/theme/notion_theme.dart';
import '../../data/repositories/admin_repository.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: NotionTheme.primaryText))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final u = _users[i];
                final isAdmin = u['isAdmin'] as bool? ?? false;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: NotionTheme.surfaceHover,
                    child: Text(
                      (u['username'] as String).substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: NotionTheme.primaryText, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Row(children: [
                    Text(u['username'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: NotionTheme.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Admin', style: TextStyle(fontSize: 10, color: NotionTheme.blueAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  subtitle: Text(u['email'] as String, style: Theme.of(context).textTheme.bodySmall),
                  trailing: TextButton(
                    onPressed: () => _toggleAdmin(u),
                    child: Text(isAdmin ? 'Remove Admin' : 'Make Admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAdmin ? NotionTheme.redAccent : NotionTheme.blueAccent,
                        )),
                  ),
                );
              },
            ),
    );
  }
}
