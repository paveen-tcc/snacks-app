import 'package:flutter/material.dart';
import '../../core/di/locator.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/illustrations.dart';
import '../../core/widgets/skeleton.dart';
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
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Remove Holiday'),
        content: const Text('Are you sure you want to remove this holiday?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Remove', style: TextStyle(color: context.palette.danger))),
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
    final name = await showAdaptiveDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
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
    final palette = context.palette;
    return Scaffold(
      appBar: const GlassAppBar(title: 'Manage Holidays'),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHoliday,
        backgroundColor: palette.brand,
        foregroundColor: palette.onBrand,
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: const [FoodListSkeleton(count: 4)],
            )
          : _holidays.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyStateIllustration(emoji: '🗓️', size: 130),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'No holidays added',
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tap + to add one',
                    style: context.text.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.page),
              itemCount: _holidays.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) {
                final h = _holidays[i];
                return AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: palette.warning.withValues(alpha: 0.14),
                          borderRadius: AppRadii.rMd,
                        ),
                        child: Icon(
                          Icons.event_busy_rounded,
                          color: palette.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h['name'] ?? 'Holiday',
                              style: context.text.titleSmall,
                            ),
                            Text(
                              _formatDate(h['date'] as String),
                              style: context.text.bodySmall?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: palette.danger,
                          size: 20,
                        ),
                        onPressed: () => _delete(h['id'] as String),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
