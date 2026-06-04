import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/snack_categories.dart';
import '../../core/di/locator.dart';
import '../../core/network/api_client.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/glass.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/food_card.dart' show VegBadge;
import '../../core/widgets/skeleton.dart';
import '../../data/repositories/admin_repository.dart';

class AdminSnacksScreen extends StatefulWidget {
  const AdminSnacksScreen({super.key});

  @override
  State<AdminSnacksScreen> createState() => _AdminSnacksScreenState();
}

class _AdminSnacksScreenState extends State<AdminSnacksScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _snacks = [];
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snacks = await locator<AdminRepository>().getAllSnacks();
      setState(() {
        _snacks = snacks;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> snack) async {
    final newVal = !(snack['isActive'] as bool? ?? true);
    try {
      await locator<AdminRepository>().updateSnack(snack['id'] as String, {
        'isActive': newVal,
      });
      await _load();
    } catch (e) {
      _showError('Failed to update snack');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _extractErrorMessage(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    return fallback;
  }

  Future<void> _downloadTemplate() async {
    final uri = Uri.parse('${ApiClient.baseUrl}/snacks/template');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    _showError('Failed to open template download');
  }

  Future<void> _uploadParsedSnacks(List<Map<String, dynamic>> snacks) async {
    if (snacks.isEmpty) {
      _showError('No valid snack rows found');
      return;
    }

    try {
      await locator<AdminRepository>().addSnacksBulk(snacks);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${snacks.length} snacks uploaded')),
      );
    } catch (e) {
      _showError(_extractErrorMessage(e, 'Failed to bulk upload snacks'));
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showError('Unable to read selected file');
        return;
      }

      final content = utf8
          .decode(bytes, allowMalformed: true)
          .replaceFirst('\uFEFF', '');
      final snacks = _parseBulkSnacks(content);
      await _uploadParsedSnacks(snacks);
    } catch (e) {
      _showError('Failed to upload file');
    }
  }

  Future<void> _deleteSnack(Map<String, dynamic> snack) async {
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Delete Snack'),
        content: Text('Delete "${snack['name']}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: context.palette.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await locator<AdminRepository>().deleteSnack(snack['id'] as String);
      await _load();
    } catch (e) {
      _showError(_extractErrorMessage(e, 'Failed to delete snack'));
    }
  }

  List<MapEntry<String, List<Map<String, dynamic>>>> _groupSnacksByCategory() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final snack in _snacks) {
      final category = displaySnackCategory(snack['category'] as String?);
      grouped.putIfAbsent(category, () => []).add(snack);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final rankCompare = snackCategoryRank(
          a.key,
        ).compareTo(snackCategoryRank(b.key));
        if (rankCompare != 0) return rankCompare;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    for (final entry in entries) {
      entry.value.sort((a, b) {
        final aOrder = (a['sortOrder'] as num?)?.toInt() ?? 0;
        final bOrder = (b['sortOrder'] as num?)?.toInt() ?? 0;
        final orderCompare = aOrder.compareTo(bOrder);
        if (orderCompare != 0) return orderCompare;
        return (a['name'] as String).toLowerCase().compareTo(
          (b['name'] as String).toLowerCase(),
        );
      });
    }

    return entries;
  }

  bool _isCategoryExpanded(String category, int index) {
    return _expandedCategories[category] ?? index == 0;
  }

  // Input styling now comes from the global theme (inputDecorationTheme).
  InputDecoration _notionInput(String label, {String? hint}) {
    return InputDecoration(labelText: label, hintText: hint);
  }

  void _showSnackForm({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final categoryCtrl = TextEditingController(
      text: existing?['category'] as String? ?? '',
    );
    final emojiCtrl = TextEditingController(text: existing?['emoji'] ?? '');
    final descCtrl = TextEditingController(
      text: existing?['description'] ?? '',
    );
    final sizeCtrl = TextEditingController(
      text: existing?['servingSize'] ?? '',
    );
    final shareCountCtrl = TextEditingController(
      text: ((existing?['shareCount'] as num?)?.toInt() ?? 1).toString(),
    );
    bool isVeg = existing?['isVeg'] ?? true;

    showGlassBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xxl,
            right: AppSpacing.xxl,
            top: AppSpacing.sm,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(
                icon: existing == null
                    ? Icons.add_circle_outline_rounded
                    : Icons.edit_outlined,
                title: existing == null ? 'Add Snack' : 'Edit Snack',
                subtitle: existing == null
                    ? 'Add a new item to the menu'
                    : 'Update snack details',
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      decoration: _notionInput('Name *'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: emojiCtrl,
                      decoration: _notionInput('Emoji'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                decoration: _notionInput('Category', hint: 'e.g. Burger'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: _notionInput('Short description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sizeCtrl,
                decoration: _notionInput('Serving size', hint: 'e.g. 2 Pcs'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shareCountCtrl,
                keyboardType: TextInputType.number,
                decoration: _notionInput(
                  'Share count',
                  hint: '1 = individual, 2 = serves 2 people',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Builder(
                builder: (context) {
                  final palette = context.palette;
                  final accent = isVeg ? palette.veg : palette.nonVeg;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: AppRadii.rMd,
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        VegBadge(isVeg: isVeg, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            isVeg ? 'Vegetarian' : 'Non-Vegetarian',
                            style: context.text.titleSmall?.copyWith(
                              color: accent,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: isVeg,
                          activeTrackColor: palette.veg,
                          onChanged: (v) => setModalState(() => isVeg = v),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: existing == null ? 'Add Snack' : 'Save Changes',
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final shareCount = int.tryParse(shareCountCtrl.text.trim());
                  if (shareCount == null || shareCount < 1) {
                    _showError(
                      'Share count must be a whole number of 1 or more',
                    );
                    return;
                  }
                  final data = {
                    'name': nameCtrl.text.trim(),
                    'category': categoryCtrl.text.trim(),
                    'emoji': emojiCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'servingSize': sizeCtrl.text.trim(),
                    'shareCount': shareCount,
                    'isVeg': isVeg,
                  };
                  Navigator.pop(ctx);
                  try {
                    if (existing != null) {
                      await locator<AdminRepository>().updateSnack(
                        existing['id'] as String,
                        data,
                      );
                    } else {
                      await locator<AdminRepository>().addSnack({
                        ...data,
                        'isActive': true,
                        'sortOrder': _snacks.length,
                      });
                    }
                    await _load();
                  } catch (e) {
                    _showError(_extractErrorMessage(e, 'Failed to save snack'));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _splitBulkRow(String row, String delimiter) {
    final values = <String>[];
    var current = '';
    var inQuotes = false;

    for (var i = 0; i < row.length; i++) {
      final char = row[i];
      final nextChar = i + 1 < row.length ? row[i + 1] : '';

      if (char == '"') {
        if (inQuotes && nextChar == '"') {
          current += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (!inQuotes && char == delimiter) {
        values.add(current.trim());
        current = '';
        continue;
      }

      current += char;
    }

    values.add(current.trim());
    return values;
  }

  bool _parseBoolToken(String raw, {required bool defaultValue}) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return defaultValue;
    if (['true', 'yes', 'y', '1', 'default', 'active'].contains(normalized)) {
      return true;
    }
    if (['false', 'no', 'n', '0', 'inactive'].contains(normalized)) {
      return false;
    }
    return defaultValue;
  }

  List<Map<String, dynamic>> _parseBulkSnacks(String raw) {
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];

    final delimiter = lines.any((line) => line.contains('\t')) ? '\t' : ',';
    final firstRow = _splitBulkRow(lines.first, delimiter);
    final hasHeader =
        firstRow.isNotEmpty && firstRow.first.toLowerCase().contains('name');
    final dataLines = hasHeader ? lines.skip(1) : lines;

    return dataLines
        .map((line) {
          final cols = _splitBulkRow(line, delimiter);
          final name = cols.isNotEmpty ? cols[0] : '';
          final category = cols.length > 1 ? cols[1] : '';
          final emoji = cols.length > 2 ? cols[2] : '';
          final description = cols.length > 3 ? cols[3] : '';
          final type = cols.length > 4 ? cols[4] : '';
          final servingSize = cols.length > 5 ? cols[5] : '';
          final shareCount = cols.length > 6 ? int.tryParse(cols[6].trim()) : 1;
          final isActive = cols.length > 7
              ? _parseBoolToken(cols[7], defaultValue: true)
              : true;
          final sortOrder = cols.length > 8
              ? int.tryParse(cols[8].trim())
              : null;
          final normalizedType = type.trim().toLowerCase();
          final isVeg = ![
            'non-veg',
            'non veg',
            'nveg',
            'nonveg',
            'false',
            'no',
            '0',
          ].contains(normalizedType);

          return {
            'name': name.trim(),
            'category': category.trim(),
            'emoji': emoji.trim(),
            'description': description.trim(),
            'isVeg': isVeg,
            'servingSize': servingSize.trim(),
            'shareCount': (shareCount != null && shareCount > 0)
                ? shareCount
                : 1,
            'isActive': isActive,
            if (sortOrder != null) 'sortOrder': sortOrder,
          };
        })
        .where((snack) => (snack['name'] as String).isNotEmpty)
        .toList();
  }

  void _showBulkUploadSheet() {
    final bulkCtrl = TextEditingController();

    showGlassBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xxl,
          right: AppSpacing.xxl,
          top: AppSpacing.sm,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHeader(
              icon: Icons.upload_file_outlined,
              title: 'Bulk Upload Snacks',
              subtitle:
                  'Paste CSV or spreadsheet rows to create multiple snacks',
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download Template'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadFile();
                },
                icon: const Icon(Icons.attach_file_outlined),
                label: const Text('Choose File And Upload'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Format: name, category, emoji, description, veg/non-veg, serving size, share count, is active, sort order',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Example: Pizza, Italian, 🍕, Cheesy pizza slices, veg, 1 box, 2, true, 10',
              style: context.text.bodySmall?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: bulkCtrl,
              minLines: 8,
              maxLines: 12,
              decoration: _notionInput('Paste rows here'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final snacks = _parseBulkSnacks(bulkCtrl.text);
                  Navigator.pop(ctx);
                  await _uploadParsedSnacks(snacks);
                },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Upload Snacks'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Manage Snacks',
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Bulk upload',
            onPressed: _showBulkUploadSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSnackForm(),
        backgroundColor: palette.brand,
        foregroundColor: palette.onBrand,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add snack'),
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: const [FoodListSkeleton(count: 6)],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.lg,
                AppSpacing.page,
                AppSpacing.x5 + AppSpacing.x4,
              ),
              children: [
                for (final entry
                    in _groupSnacksByCategory().asMap().entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedCategories[entry.value.key] =
                                  !_isCategoryExpanded(
                                    entry.value.key,
                                    entry.key,
                                  );
                            });
                          },
                          borderRadius: AppRadii.rMd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: AppRadii.rMd,
                              border: Border.all(color: palette.border),
                              boxShadow: context.shadows.sm,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.value.key,
                                    style: context.text.titleMedium,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.brand.withValues(alpha: 0.12),
                                    borderRadius: AppRadii.rPill,
                                  ),
                                  child: Text(
                                    '${entry.value.value.length}',
                                    style: context.text.labelMedium?.copyWith(
                                      color: palette.brand,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Icon(
                                  _isCategoryExpanded(
                                        entry.value.key,
                                        entry.key,
                                      )
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: palette.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Column(
                              children: [
                                for (final snack in entry.value.value)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: _buildSnackListTile(snack),
                                  ),
                              ],
                            ),
                          ),
                          crossFadeState:
                              _isCategoryExpanded(entry.value.key, entry.key)
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: AppMotion.base,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSnackListTile(Map<String, dynamic> s) {
    final palette = context.palette;
    final isActive = s['isActive'] as bool? ?? true;
    final isVeg = s['isVeg'] as bool? ?? true;
    final category = displaySnackCategory(s['category'] as String?);
    final description = (s['description'] as String? ?? '').trim();
    final servingSize = (s['servingSize'] as String? ?? '').trim();
    final shareCount = (s['shareCount'] as num?)?.toInt() ?? 1;

    Widget chip(String label) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(color: palette.textSecondary),
      ),
    );

    return Opacity(
      opacity: isActive ? 1 : 0.55,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadii.rMd,
              ),
              alignment: Alignment.center,
              child: Text(
                s['emoji'] ?? '🍽️',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VegBadge(isVeg: isVeg),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          s['name'] as String,
                          style: context.text.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      chip(category),
                      if (servingSize.isNotEmpty) chip(servingSize),
                      if (shareCount > 1) chip('Serves $shareCount'),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      description,
                      style: context.text.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _showSnackForm(existing: s),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: palette.danger,
                      ),
                      tooltip: 'Delete snack',
                      onPressed: () => _deleteSnack(s),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: isActive,
                  activeTrackColor: palette.veg,
                  onChanged: (_) => _toggleActive(s),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact header used inside the snack add/edit and bulk-upload glass sheets.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: palette.brand.withValues(alpha: 0.12),
            borderRadius: AppRadii.rMd,
          ),
          child: Icon(icon, color: palette.brand),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleLarge),
              Text(
                subtitle,
                style: context.text.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
