import 'package:flutter/material.dart';
import '../../core/di/locator.dart';
import '../../core/theme/notion_theme.dart';
import '../../core/widgets/illustrations.dart';
import '../../data/repositories/admin_repository.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _loading = true;
  Map<String, dynamic> _settings = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await locator<AdminRepository>().getSettings();
      setState(() { _settings = settings; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _edit(String key, String label, String currentValue, {TextInputType? keyboardType}) async {
    final ctrl = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: 'Enter $label'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != currentValue) {
      try {
        await locator<AdminRepository>().updateSetting(key, result);
        await _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: FoodLoader())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(context, 'Order Settings', [
                  _buildSettingTile(
                    context,
                    icon: Icons.timer,
                    title: 'Order Cutoff Time',
                    subtitle: _settings['cutoff_time'] ?? '12:00',
                    onTap: () => _edit('cutoff_time', 'Cutoff Time (HH:MM)', _settings['cutoff_time'] ?? '12:00'),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSection(context, 'WhatsApp', [
                  _buildSettingTile(
                    context,
                    icon: Icons.phone,
                    title: 'WhatsApp Number',
                    subtitle: _settings['whatsapp_number'] ?? 'Not set',
                    onTap: () => _edit('whatsapp_number', 'Phone Number (with country code)', _settings['whatsapp_number'] ?? '',
                        keyboardType: TextInputType.phone),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.group,
                    title: 'Is WhatsApp Group?',
                    subtitle: _settings['whatsapp_is_group'] == 'true' ? 'Yes' : 'No',
                    onTap: () {
                      final current = _settings['whatsapp_is_group'] == 'true';
                      locator<AdminRepository>().updateSetting('whatsapp_is_group', (!current).toString()).then((_) => _load());
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSection(context, 'Holidays', [
                  _buildSettingTile(
                    context,
                    icon: Icons.public,
                    title: 'Holiday Country Code',
                    subtitle: _settings['holiday_country'] ?? 'IN',
                    onTap: () => _edit('holiday_country', 'Country Code (e.g. IN, US)', _settings['holiday_country'] ?? 'IN'),
                  ),
                ]),
              ],
            ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold, color: NotionTheme.secondaryText)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(border: Border.all(color: NotionTheme.border), borderRadius: BorderRadius.circular(8)),
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

  Widget _buildSettingTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: NotionTheme.primaryText),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: NotionTheme.secondaryText),
      onTap: onTap,
    );
  }
}
