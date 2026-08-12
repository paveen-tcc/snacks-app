import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/snack_categories.dart';
import '../../core/di/locator.dart';
import '../../core/formatters/rupees.dart';
import '../../core/network/api_client.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/glass.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/food_card.dart' show VegBadge;
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/optimized_image.dart';
import '../../data/repositories/admin_repository.dart';
import 'bulk_snack_parser.dart';

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
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;

      // On mobile platforms file.bytes is often null; read via File(path).
      Uint8List? bytes = file.bytes;
      if ((bytes == null || bytes.isEmpty) && !kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null || bytes.isEmpty) {
        _showError('Unable to read selected file');
        return;
      }

      final content = utf8
          .decode(bytes, allowMalformed: true)
          .replaceFirst('\uFEFF', '');
      final snacks = parseBulkSnacks(content);
      await _uploadParsedSnacks(snacks);
    } on BulkSnackParseException catch (error) {
      _showError(error.message);
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

  /// Build a unique, case-insensitive list of categories from DB + predefined.
  List<String> _buildCategoryList() {
    final seen = <String, String>{}; // lowercase -> original case
    // Add predefined categories first
    for (final cat in snackCategoryOrder) {
      seen.putIfAbsent(cat.toLowerCase(), () => cat);
    }
    // Always add Drinks to category list
    seen.putIfAbsent('drinks', () => 'Drinks');

    // Add categories from existing snacks
    for (final snack in _snacks) {
      final cat = (snack['category'] as String? ?? '').trim();
      if (cat.isNotEmpty) {
        seen.putIfAbsent(cat.toLowerCase(), () => cat);
      }
    }
    return seen.values.toList();
  }

  /// Match a user-typed category against existing ones (case-insensitive).
  String _normalizeCategoryInput(String input, List<String> categories) {
    final lower = input.toLowerCase();
    for (final cat in categories) {
      if (cat.toLowerCase() == lower) return cat;
    }
    return input; // no match, keep as-is
  }

  void _showSnackForm({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final emojiCtrl = TextEditingController(text: existing?['emoji'] ?? '');
    final sizeCtrl = TextEditingController(
      text: existing?['servingSize'] ?? '',
    );
    final shareCountCtrl = TextEditingController(
      text: ((existing?['shareCount'] as num?)?.toInt() ?? 1).toString(),
    );
    final priceCtrl = TextEditingController(
      text: ((existing?['priceRupees'] as num?)?.toInt() ?? 0).toString(),
    );
    bool isVeg = existing?['isVeg'] ?? true;

    final categories = _buildCategoryList();
    const customOption = 'Custom...';
    final existingCategory = (existing?['category'] as String? ?? '').trim();

    // Determine initial dropdown value
    String? selectedCategory;
    bool showCustomField = false;
    final customCategoryCtrl = TextEditingController();

    if (existingCategory.isNotEmpty) {
      final match = categories.firstWhere(
        (c) => c.toLowerCase() == existingCategory.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        selectedCategory = match;
      } else {
        // Existing category not in our list — show as custom
        selectedCategory = customOption;
        showCustomField = true;
        customCategoryCtrl.text = existingCategory;
      }
    }

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
              TextField(
                controller: nameCtrl,
                decoration: _notionInput('Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiCtrl,
                decoration: _notionInput(
                  'Image URL',
                  hint: 'https://images.unsplash.com/...',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: _notionInput('Category'),
                isExpanded: true,
                items: [
                  ...categories.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  ),
                  const DropdownMenuItem(
                    value: customOption,
                    child: Text('Custom...'),
                  ),
                ],
                onChanged: (value) {
                  setModalState(() {
                    selectedCategory = value;
                    showCustomField = value == customOption;
                    if (!showCustomField) {
                      customCategoryCtrl.clear();
                    }
                  });
                },
              ),
              if (showCustomField) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: customCategoryCtrl,
                  decoration: _notionInput(
                    'Custom category',
                    hint: 'e.g. Wraps',
                  ),
                ),
              ],

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
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: _notionInput('Price (₹)', hint: 'e.g. 25'),
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
                  final priceRupees = parseWholeRupees(priceCtrl.text);
                  if (priceRupees == null) {
                    _showError('Price must be a non-negative whole number');
                    return;
                  }

                  // Resolve category from dropdown or custom text
                  String categoryValue;
                  if (showCustomField) {
                    final raw = customCategoryCtrl.text.trim();
                    categoryValue = _normalizeCategoryInput(raw, categories);
                  } else {
                    categoryValue = selectedCategory ?? '';
                  }

                  final data = {
                    'name': nameCtrl.text.trim(),
                    'category': categoryValue,
                    'emoji': emojiCtrl.text.trim(),
                    'servingSize': sizeCtrl.text.trim(),
                    'shareCount': shareCount,
                    'priceRupees': priceRupees,
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
              'Format: name, category, image URL, veg/non-veg, serving size, share count, price rupees, is active, sort order',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Example: Pizza, Italian, https://images.unsplash.com/photo-xxx, veg, 1 box, 2, 250, true, 10',
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
                  try {
                    final snacks = parseBulkSnacks(bulkCtrl.text);
                    Navigator.pop(ctx);
                    await _uploadParsedSnacks(snacks);
                  } on BulkSnackParseException catch (error) {
                    _showError(error.message);
                  }
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
                                    color: palette.brand.withValues(
                                      alpha: 0.12,
                                    ),
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
    final servingSize = (s['servingSize'] as String? ?? '').trim();
    final shareCount = (s['shareCount'] as num?)?.toInt() ?? 1;
    final priceRupees = (s['priceRupees'] as num?)?.toInt() ?? 0;

    Widget chip(String label, {Color? background, Color? foreground}) =>
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: background ?? palette.surfaceMuted,
            borderRadius: AppRadii.rPill,
          ),
          child: Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: foreground ?? palette.textSecondary,
            ),
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
              child:
                  s['emoji'] != null &&
                      (s['emoji'] as String).startsWith('http')
                  ? OptimizedImage(
                      imageUrl: s['emoji'] as String,
                      width: 42,
                      height: 42,
                      memCacheWidth: 90,
                      memCacheHeight: 90,
                      borderRadius: AppRadii.rMd,
                      fallbackIcon: Icon(
                        Icons.fastfood_rounded,
                        size: 20,
                        color: palette.textSecondary,
                      ),
                    )
                  : Text(
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
                      chip(formatRupees(priceRupees)),
                      if (priceRupees == 0)
                        chip(
                          'Price needed',
                          background: palette.warning.withValues(alpha: 0.14),
                          foreground: palette.warning,
                        ),
                    ],
                  ),
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
