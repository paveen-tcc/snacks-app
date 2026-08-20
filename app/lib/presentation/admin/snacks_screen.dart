import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/food_assets.dart';
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
import '../../core/widgets/category_scroller.dart';
import '../../core/widgets/food_card.dart' show VegBadge;
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/optimized_image.dart';
import '../../data/repositories/admin_repository.dart';
import '../home/widgets/dispenser/drink_dispenser_models.dart';
import 'bulk_snack_parser.dart';

@visibleForTesting
bool isAdminDrinkItem(Map<String, dynamic> item) =>
    normalizeSnackCategory(item['category'] as String?) == 'drinks';

@visibleForTesting
List<Map<String, dynamic>> filterAdminMenuItems(
  Iterable<Map<String, dynamic>> items, {
  required bool drinksTab,
  required String query,
  String category = 'All',
  DrinkFormat? drinkFormat,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return items.where((item) {
    if (isAdminDrinkItem(item) != drinksTab) return false;
    final name = item['name'] as String? ?? '';
    if (normalizedQuery.isNotEmpty &&
        !name.toLowerCase().contains(normalizedQuery)) {
      return false;
    }
    if (drinksTab) {
      return drinkFormat == null ||
          DrinkPresentation.fromName(name).format == drinkFormat;
    }
    return category == 'All' ||
        normalizeSnackCategory(item['category'] as String?) ==
            category.toLowerCase();
  }).toList();
}

class AdminSnacksScreen extends StatefulWidget {
  const AdminSnacksScreen({super.key});

  @override
  State<AdminSnacksScreen> createState() => _AdminSnacksScreenState();
}

class _AdminSnacksScreenState extends State<AdminSnacksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _snacks = [];
  String _snackQuery = '';
  String _drinkQuery = '';
  String _snackCategory = 'All';
  DrinkFormat? _drinkFormat;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChanged);
    _load();
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (mounted && _activeTabIndex != _tabController.index) {
      setState(() => _activeTabIndex = _tabController.index);
    }
  }

  bool get _showingDrinks => _activeTabIndex == 1;

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

  List<MapEntry<String, List<Map<String, dynamic>>>> _groupSnacksByCategory(
    Iterable<Map<String, dynamic>> snacks,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final snack in snacks) {
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

  List<MapEntry<String, List<Map<String, dynamic>>>> _groupDrinksByFormat(
    Iterable<Map<String, dynamic>> drinks,
  ) {
    final grouped = <DrinkFormat, List<Map<String, dynamic>>>{};
    for (final drink in drinks) {
      final name = drink['name'] as String? ?? '';
      final format = DrinkPresentation.fromName(name).format;
      grouped.putIfAbsent(format, () => []).add(drink);
    }

    return DrinkFormat.values.where(grouped.containsKey).map((format) {
      final values = grouped[format]!;
      _sortMenuItems(values);
      return MapEntry(drinkFormatLabel(format), values);
    }).toList();
  }

  void _sortMenuItems(List<Map<String, dynamic>> items) {
    items.sort((a, b) {
      final aOrder = (a['sortOrder'] as num?)?.toInt() ?? 0;
      final bOrder = (b['sortOrder'] as num?)?.toInt() ?? 0;
      final orderComparison = aOrder.compareTo(bOrder);
      if (orderComparison != 0) return orderComparison;
      final aName = (a['name'] as String? ?? '').toLowerCase();
      final bName = (b['name'] as String? ?? '').toLowerCase();
      return aName.compareTo(bName);
    });
  }

  List<String> _foodCategoryOptions() {
    return buildSnackCategoryOptions(
      _snacks
          .where((item) => !isAdminDrinkItem(item))
          .map((item) => item['category'] as String?),
    );
  }

  List<Map<String, dynamic>> _visibleItems() {
    final categories = _foodCategoryOptions();
    final selectedCategory = categories.contains(_snackCategory)
        ? _snackCategory
        : 'All';
    return filterAdminMenuItems(
      _snacks,
      drinksTab: _showingDrinks,
      query: _showingDrinks ? _drinkQuery : _snackQuery,
      category: selectedCategory,
      drinkFormat: _showingDrinks ? _drinkFormat : null,
    );
  }

  List<MapEntry<String, List<Map<String, dynamic>>>> _visibleGroups() {
    final visible = _visibleItems();
    return _showingDrinks
        ? _groupDrinksByFormat(visible)
        : _groupSnacksByCategory(visible);
  }

  InputDecoration _sheetInput(BuildContext context, {String? hint}) {
    final palette = context.palette;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadii.rMd,
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.rMd,
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.rMd,
        borderSide: BorderSide(color: palette.brand, width: 1.6),
      ),
    );
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

  void _showSnackForm({
    Map<String, dynamic>? existing,
    String? defaultCategory,
  }) {
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
    final existingCategory =
        (existing?['category'] as String? ?? defaultCategory ?? '').trim();
    final isDrinkForm = existingCategory.toLowerCase() == 'drinks';
    final itemLabel = isDrinkForm ? 'Drink' : 'Snack';

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
        builder: (ctx, setModalState) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: AppSpacing.page,
            right: AppSpacing.page,
            top: AppSpacing.sm,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(
                icon: existing == null
                    ? Icons.add_circle_outline_rounded
                    : Icons.edit_outlined,
                title: existing == null ? 'Add $itemLabel' : 'Edit $itemLabel',
                subtitle: existing == null
                    ? 'Add a new item to the menu'
                    : 'Update snack details',
                onClose: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SheetFormField(
                label: 'Name',
                isRequired: true,
                child: TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _sheetInput(ctx, hint: 'Enter the snack name'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SheetFormField(
                label: 'Image URL',
                child: TextField(
                  controller: emojiCtrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: _sheetInput(
                    ctx,
                    hint: 'https://images.unsplash.com/...',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SheetFormField(
                label: 'Category',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Theme(
                      data: Theme.of(ctx).copyWith(
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        splashColor: ctx.palette.brand.withValues(alpha: 0.08),
                      ),
                      child: PopupMenuButton<String>(
                        tooltip: 'Select category',
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          maxWidth: constraints.maxWidth,
                          maxHeight: 260,
                        ),
                        color: ctx.palette.surfaceElevated,
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.rLg,
                          side: BorderSide(color: ctx.palette.border),
                        ),
                        position: PopupMenuPosition.under,
                        onSelected: (value) {
                          setModalState(() {
                            selectedCategory = value;
                            showCustomField = value == customOption;
                            if (!showCustomField) {
                              customCategoryCtrl.clear();
                            }
                          });
                        },
                        itemBuilder: (context) => [
                          ...categories.map((c) {
                            final isSelected = c == selectedCategory;
                            return PopupMenuItem<String>(
                              value: c,
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ctx.palette.brand.withValues(alpha: 0.10)
                                      : Colors.transparent,
                                  borderRadius: AppRadii.rMd,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? ctx.palette.brand
                                              : ctx.palette.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: ctx.palette.brand,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          PopupMenuItem<String>(
                            value: customOption,
                            height: 40,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selectedCategory == customOption
                                    ? ctx.palette.brand.withValues(alpha: 0.10)
                                    : Colors.transparent,
                                borderRadius: AppRadii.rMd,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Custom...',
                                      style: TextStyle(
                                        fontWeight: selectedCategory == customOption
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selectedCategory == customOption
                                            ? ctx.palette.brand
                                            : ctx.palette.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (selectedCategory == customOption)
                                    Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: ctx.palette.brand,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: ctx.palette.surface,
                            borderRadius: AppRadii.rLg,
                            border: Border.all(color: ctx.palette.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedCategory == customOption
                                      ? 'Custom...'
                                      : (selectedCategory ?? 'Select a category'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: selectedCategory != null
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    color: selectedCategory != null
                                        ? ctx.palette.textPrimary
                                        : ctx.palette.textTertiary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: ctx.palette.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (showCustomField) ...[
                const SizedBox(height: AppSpacing.lg),
                _SheetFormField(
                  label: 'Custom category',
                  child: TextField(
                    controller: customCategoryCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _sheetInput(ctx, hint: 'e.g. Wraps'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _SheetFormField(
                label: 'Serving size',
                child: TextField(
                  controller: sizeCtrl,
                  decoration: _sheetInput(ctx, hint: 'e.g. 2 Pcs'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SheetFormField(
                      label: 'Share count',
                      child: TextField(
                        controller: shareCountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _sheetInput(ctx),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SheetFormField(
                      label: 'Price (₹)',
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _sheetInput(ctx),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
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
                label: existing == null ? 'Add $itemLabel' : 'Save Changes',
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
              decoration: _sheetInput(ctx, hint: 'Paste rows here'),
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
    final addLabel = _showingDrinks ? 'Add drink' : 'Add snack';
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(key: Key('manage-menu-tab-snacks'), text: 'Snacks'),
            Tab(key: Key('manage-menu-tab-drinks'), text: 'Drinks'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showSnackForm(defaultCategory: _showingDrinks ? 'Drinks' : null),
        backgroundColor: palette.brand,
        foregroundColor: palette.onBrand,
        icon: const Icon(Icons.add_rounded),
        label: Text(addLabel),
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.page),
              children: const [FoodListSkeleton(count: 6)],
            )
          : Column(
              children: [
                _buildFilterControls(),
                Expanded(child: _buildGroupedList()),
              ],
            ),
    );
  }

  Widget _buildFilterControls() {
    final categories = _foodCategoryOptions();
    final selectedCategory = categories.contains(_snackCategory)
        ? _snackCategory
        : 'All';
    final query = _showingDrinks ? _drinkQuery : _snackQuery;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.sm,
          ),
          child: _AdminMenuSearchField(
            key: ValueKey(_showingDrinks ? 'drink-search' : 'snack-search'),
            query: query,
            hint: _showingDrinks ? 'Search drinks' : 'Search snacks',
            onChanged: (value) {
              setState(() {
                if (_showingDrinks) {
                  _drinkQuery = value;
                } else {
                  _snackQuery = value;
                }
              });
            },
          ),
        ),
        CategoryScroller(
          items: _showingDrinks
              ? _drinkFilterItems()
              : _foodFilterItems(categories),
          selectedKey: _showingDrinks
              ? (_drinkFormat?.name ?? 'all')
              : selectedCategory,
          onSelected: (key) {
            setState(() {
              if (_showingDrinks) {
                _drinkFormat = key == 'all'
                    ? null
                    : DrinkFormat.values.byName(key);
              } else {
                _snackCategory = key;
              }
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  List<CategoryItem> _foodFilterItems(List<String> categories) {
    return categories.map((category) {
      final icons = snackCategoryIconPair(category);
      return CategoryItem(
        key: category,
        label: category,
        icon: icons.unselected,
        selectedIcon: icons.selected,
      );
    }).toList();
  }

  List<CategoryItem> _drinkFilterItems() {
    final allIcons = snackCategoryIconPair('All');
    return [
      CategoryItem(
        key: 'all',
        label: 'All',
        icon: allIcons.unselected,
        selectedIcon: allIcons.selected,
      ),
      for (final format in DrinkFormat.values)
        CategoryItem(
          key: format.name,
          label: drinkFormatLabel(format),
          icon: drinkFormatIcon(format),
          selectedIcon: drinkFormatIcon(format),
        ),
    ];
  }

  Widget _buildGroupedList() {
    final groups = _visibleGroups();
    if (groups.isEmpty) {
      final query = _showingDrinks ? _drinkQuery.trim() : _snackQuery.trim();
      return _AdminMenuEmptyState(
        title: _showingDrinks ? 'No drinks found' : 'No snacks found',
        subtitle: query.isEmpty
            ? 'Try another category.'
            : 'Nothing matches “$query”.',
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.x5 + AppSpacing.x4,
      ),
      children: [
        for (final entry in groups.asMap().entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildMenuGroup(
              entry.value.key,
              entry.value.value,
              entry.key,
            ),
          ),
      ],
    );
  }

  Widget _buildMenuGroup(
    String label,
    List<Map<String, dynamic>> items,
    int index,
  ) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                label,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: palette.brand.withValues(alpha: 0.12),
                  borderRadius: AppRadii.rPill,
                ),
                child: Text(
                  '${items.length}',
                  style: context.text.labelSmall?.copyWith(
                    color: palette.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildSnackListTile(item),
          ),
      ],
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
            Builder(
              builder: (context) {
                final localAsset = resolveLocalFoodAsset(s['name'] as String?);
                return Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.isDark ? palette.surface : Colors.white,
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.05),
                      radius: 0.85,
                      colors: palette.cardGlowGradient,
                      stops: palette.isDark
                          ? const [0.0, 0.55, 1.0]
                          : const [0.0, 0.55, 1.0],
                    ),
                    borderRadius: AppRadii.rMd,
                    border: Border.all(
                      color: palette.isDark
                          ? palette.border
                          : const Color(0xFFE5ECF6),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: localAsset != null
                      ? Padding(
                          padding: const EdgeInsets.all(3),
                          child: Image.asset(
                            localAsset,
                            fit: BoxFit.contain,
                            cacheWidth: 120,
                            errorBuilder: (c, e, s) => Icon(
                              Icons.fastfood_rounded,
                              size: 20,
                              color: palette.textSecondary,
                            ),
                          ),
                        )
                      : s['emoji'] != null &&
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
                );
              },
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

class _AdminMenuSearchField extends StatefulWidget {
  const _AdminMenuSearchField({
    super.key,
    required this.query,
    required this.hint,
    required this.onChanged,
  });

  final String query;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_AdminMenuSearchField> createState() => _AdminMenuSearchFieldState();
}

class _AdminMenuSearchFieldState extends State<_AdminMenuSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _AdminMenuSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) _controller.text = widget.query;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        key: const Key('manage-menu-search'),
        controller: _controller,
        onChanged: (value) {
          widget.onChanged(value);
          setState(() {});
        },
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 21),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear_rounded, size: 19),
                ),
          isDense: true,
        ),
      ),
    );
  }
}

class _AdminMenuEmptyState extends StatelessWidget {
  const _AdminMenuEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: context.palette.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact header used inside the snack add/edit and bulk-upload sheets.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onClose,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onClose;

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
        if (onClose != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton.filledTonal(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ],
    );
  }
}

class _SheetFormField extends StatelessWidget {
  const _SheetFormField({
    required this.label,
    required this.child,
    this.isRequired = false,
  });

  final String label;
  final Widget child;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: palette.danger),
                ),
            ],
          ),
          style: context.text.labelMedium?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
