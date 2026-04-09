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

  Future<void> _updateToggleSetting(String key, dynamic value) async {
    final previousValue = _settings[key];
    setState(() {
      _settings[key] = value;
    });

    try {
      await locator<AdminRepository>().updateSetting(key, value);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _settings[key] = previousValue;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save')));
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await locator<AdminRepository>().getSettings();
      setState(() {
        _settings = settings;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'cutoff_time':
        return Icons.timer;
      case 'advance_window_start':
      case 'advance_window_end':
        return Icons.schedule;
      case 'whatsapp_number':
        return Icons.phone;
      case 'holiday_country':
        return Icons.public;
      default:
        return Icons.settings;
    }
  }

  Future<void> _edit(
    String key,
    String label,
    String currentValue, {
    TextInputType? keyboardType,
  }) async {
    final ctrl = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DialogHeader(
                icon: _iconForKey(key),
                title: label,
                subtitle: 'Update the value below',
                backgroundColor: IllustrationColors.softBlue,
                iconColor: NotionTheme.blueAccent,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                keyboardType: keyboardType,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter $label',
                  hintStyle: TextStyle(
                    color: NotionTheme.secondaryText.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: NotionTheme.surfaceHover,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: NotionTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: NotionTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: NotionTheme.blueAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NotionTheme.secondaryText,
                        side: BorderSide(color: NotionTheme.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NotionTheme.primaryText,
                        foregroundColor: NotionTheme.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result != currentValue) {
      try {
        await locator<AdminRepository>().updateSetting(key, result);
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to save')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                    onTap: () => _edit(
                      'cutoff_time',
                      'Cutoff Time (HH:MM)',
                      _settings['cutoff_time'] ?? '12:00',
                    ),
                  ),
                  _buildToggleTile(
                    context,
                    icon: Icons.event_available,
                    title: 'Advance Order Mode',
                    subtitle:
                        'When ON, morning orders are placed for the next day.',
                    value: _settings['advance_order_mode'] == true,
                    onChanged: (val) =>
                        _updateToggleSetting('advance_order_mode', val),
                  ),
                  if (_settings['advance_order_mode'] == true)
                    _buildSettingTile(
                      context,
                      icon: Icons.schedule,
                      title: 'Advance Window Start',
                      subtitle: _settings['advance_window_start'] ?? '06:00',
                      onTap: () => _edit(
                        'advance_window_start',
                        'Advance Window Start (HH:MM)',
                        _settings['advance_window_start'] ?? '06:00',
                      ),
                    ),
                  if (_settings['advance_order_mode'] == true)
                    _buildSettingTile(
                      context,
                      icon: Icons.schedule,
                      title: 'Advance Window End',
                      subtitle: _settings['advance_window_end'] ?? '22:00',
                      onTap: () => _edit(
                        'advance_window_end',
                        'Advance Window End (HH:MM)',
                        _settings['advance_window_end'] ?? '22:00',
                      ),
                    ),
                ]),
                const SizedBox(height: 24),
                _buildSection(context, 'Holidays', [
                  _buildSettingTile(
                    context,
                    icon: Icons.public,
                    title: 'Holiday Country Code',
                    subtitle: _settings['holiday_country'] ?? 'IN',
                    onTap: () => _edit(
                      'holiday_country',
                      'Country Code (e.g. IN, US)',
                      _settings['holiday_country'] ?? 'IN',
                    ),
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
            children: items
                .asMap()
                .entries
                .map(
                  (e) => Column(
                    children: [
                      e.value,
                      if (e.key < items.length - 1) const Divider(height: 1),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: NotionTheme.primaryText),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(
        Icons.chevron_right,
        color: NotionTheme.secondaryText,
      ),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: NotionTheme.primaryText),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Transform.scale(
        scale: 0.85,
        child: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}
