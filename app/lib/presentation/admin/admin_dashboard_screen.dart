import 'package:flutter/material.dart';
import '../../core/theme/notion_theme.dart';
import 'summary_screen.dart';
import 'snacks_screen.dart';
import 'settings_screen.dart';
import 'holidays_screen.dart';
import 'users_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(context, 'Daily Operations', [
            _buildItem(context, Icons.summarize, "Today's Summary", 'View snack counts and drink poll results',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen()))),
          ]),
          const SizedBox(height: 24),
          _buildSection(context, 'Menu Management', [
            _buildItem(context, Icons.fastfood, 'Manage Snacks', 'Add, edit, toggle active/default',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSnacksScreen()))),
          ]),
          const SizedBox(height: 24),
          _buildSection(context, 'Settings & Holidays', [
            _buildItem(context, Icons.settings, 'App Settings', 'Cutoff time, WhatsApp number',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen()))),
            _buildItem(context, Icons.event_busy, 'Manage Holidays', 'Add or remove shutdown days',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHolidaysScreen()))),
          ]),
          const SizedBox(height: 24),
          _buildSection(context, 'Users', [
            _buildItem(context, Icons.admin_panel_settings, 'Manage Users', 'Grant or revoke admin access',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()))),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: NotionTheme.secondaryText)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: NotionTheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: items.asMap().entries.map((e) => Column(children: [
              e.value,
              if (e.key < items.length - 1) const Divider(height: 1),
            ])).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: NotionTheme.primaryText),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: NotionTheme.secondaryText),
      onTap: onTap,
    );
  }
}
