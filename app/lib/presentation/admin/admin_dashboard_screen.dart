import 'package:flutter/material.dart';
import '../../core/theme/notion_theme.dart';

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
          _buildAdminSection(context, 'Daily Operations', [
            _buildAdminItem(
              context,
              Icons.summarize,
              'Today\'s Summary',
              'View total snack counts and poll results',
            ),
            _buildAdminItem(
              context,
              Icons.send,
              'Send to WhatsApp',
              'Generate message template',
            ),
          ]),
          const SizedBox(height: 24),
          _buildAdminSection(context, 'Menu Management', [
            _buildAdminItem(
              context,
              Icons.fastfood,
              'Manage Snacks',
              'Add, edit, or disable snacks',
            ),
            _buildAdminItem(
              context,
              Icons.star,
              'Set Default Snack',
              'Currently: Samosa',
            ),
          ]),
          const SizedBox(height: 24),
          _buildAdminSection(context, 'Settings & Holidays', [
            _buildAdminItem(
              context,
              Icons.timer,
              'Order Cutoff Time',
              'Currently: 12:00 PM',
            ),
            _buildAdminItem(
              context,
              Icons.event_busy,
              'Manage Holidays',
              'Add or remove shutdown days',
            ),
            _buildAdminItem(
              context,
              Icons.admin_panel_settings,
              'Manage Admins',
              'Promote users to admin',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildAdminSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: NotionTheme.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: NotionTheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListTile(
      leading: Icon(icon, color: NotionTheme.primaryText),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(
        Icons.chevron_right,
        color: NotionTheme.secondaryText,
      ),
      onTap: () {
        // TODO: Navigate to specific admin feature
      },
    );
  }
}
