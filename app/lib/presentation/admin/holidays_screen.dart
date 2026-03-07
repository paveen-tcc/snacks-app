import 'package:flutter/material.dart';
import '../../core/di/locator.dart';
import '../../core/theme/notion_theme.dart';
import '../../data/repositories/admin_repository.dart';

class AdminHolidaysScreen extends StatefulWidget {
  const AdminHolidaysScreen({super.key});

  @override
  State<AdminHolidaysScreen> createState() => _AdminHolidaysScreenState();
}

class _AdminHolidaysScreenState extends State<AdminHolidaysScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _holidays = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final holidays = await locator<AdminRepository>().getHolidays();
      setState(() { _holidays = holidays; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Holiday'),
        content: const Text('Are you sure you want to remove this holiday?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: NotionTheme.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      await locator<AdminRepository>().deleteHoliday(id);
      await _load();
    }
  }

  Future<void> _addHoliday() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;

    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Holiday Name'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: 'e.g. Diwali, Christmas'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()), child: const Text('Add')),
        ],
      ),
    );

    if (name != null) {
      final dateStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await locator<AdminRepository>().addHoliday(dateStr, name);
      await _load();
    }
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.parse(dateStr);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Holidays'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHoliday,
        backgroundColor: NotionTheme.primaryText,
        child: const Icon(Icons.add, color: NotionTheme.background),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: NotionTheme.primaryText))
          : _holidays.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🗓️', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('No holidays added', style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      Text('Tap + to add one', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _holidays.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final h = _holidays[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_busy, color: NotionTheme.secondaryText),
                      title: Text(h['name'] ?? 'Holiday', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(_formatDate(h['date'] as String), style: Theme.of(context).textTheme.bodySmall),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: NotionTheme.redAccent, size: 20),
                        onPressed: () => _delete(h['id'] as String),
                      ),
                    );
                  },
                ),
    );
  }
}
