import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/snack_categories.dart';
import '../../core/di/locator.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/notion_theme.dart';
import '../../core/widgets/illustrations.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Snack'),
        content: Text('Delete "${snack['name']}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
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

  InputDecoration _notionInput(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: NotionTheme.secondaryText, fontSize: 13),
      hintStyle: TextStyle(
        color: NotionTheme.secondaryText.withValues(alpha: 0.4),
      ),
      filled: true,
      fillColor: NotionTheme.surfaceHover,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: BorderSide(color: NotionTheme.blueAccent, width: 1.5),
      ),
    );
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NotionTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: NotionTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              DialogHeader(
                icon: existing == null
                    ? Icons.add_circle_outline
                    : Icons.edit_outlined,
                title: existing == null ? 'Add Snack' : 'Edit Snack',
                subtitle: existing == null
                    ? 'Add a new item to the menu'
                    : 'Update snack details',
                backgroundColor: existing == null
                    ? IllustrationColors.softGreen
                    : IllustrationColors.softBlue,
                iconColor: existing == null
                    ? NotionTheme.greenAccent
                    : NotionTheme.blueAccent,
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isVeg
                      ? NotionTheme.greenAccent.withValues(alpha: 0.08)
                      : NotionTheme.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isVeg
                        ? NotionTheme.greenAccent.withValues(alpha: 0.3)
                        : NotionTheme.redAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isVeg
                            ? NotionTheme.greenAccent
                            : NotionTheme.redAccent,
                      ),
                      child: Icon(
                        isVeg ? Icons.eco : Icons.restaurant,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isVeg ? 'Vegetarian' : 'Non-Vegetarian',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isVeg
                              ? NotionTheme.greenAccent
                              : NotionTheme.redAccent,
                        ),
                      ),
                    ),
                    Switch(
                      value: isVeg,
                      activeThumbColor: NotionTheme.greenAccent,
                      inactiveThumbColor: NotionTheme.redAccent,
                      onChanged: (v) => setModalState(() => isVeg = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
                      _showError(
                        _extractErrorMessage(e, 'Failed to save snack'),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NotionTheme.primaryText,
                    foregroundColor: NotionTheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(existing == null ? 'Add Snack' : 'Save Changes'),
                ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NotionTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NotionTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const DialogHeader(
              icon: Icons.upload_file_outlined,
              title: 'Bulk Upload Snacks',
              subtitle:
                  'Paste CSV or spreadsheet rows to create multiple snacks',
              backgroundColor: IllustrationColors.softBlue,
              iconColor: NotionTheme.blueAccent,
            ),
            const SizedBox(height: 16),
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: NotionTheme.secondaryText),
            ),
            const SizedBox(height: 16),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Snacks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _showBulkUploadSheet,
            backgroundColor: NotionTheme.blueAccent,
            icon: const Icon(Icons.upload_file_outlined, color: Colors.white),
            label: const Text(
              'Bulk Upload',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () => _showSnackForm(),
            backgroundColor: NotionTheme.primaryText,
            child: const Icon(Icons.add, color: NotionTheme.background),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: FoodLoader())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry
                    in _groupSnacksByCategory().asMap().entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 6),
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
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: NotionTheme.surfaceHover,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: NotionTheme.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.value.key,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: NotionTheme.surfaceSelected,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${entry.value.value.length}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _isCategoryExpanded(
                                        entry.value.key,
                                        entry.key,
                                      )
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: NotionTheme.secondaryText,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              children: [
                                for (final snack in entry.value.value) ...[
                                  _buildSnackListTile(snack),
                                  const Divider(height: 1),
                                ],
                              ],
                            ),
                          ),
                          crossFadeState:
                              _isCategoryExpanded(entry.value.key, entry.key)
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
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
    final isActive = s['isActive'] as bool? ?? true;
    final isVeg = s['isVeg'] as bool? ?? true;
    final category = displaySnackCategory(s['category'] as String?);
    final description = (s['description'] as String? ?? '').trim();
    final servingSize = (s['servingSize'] as String? ?? '').trim();
    final shareCount = (s['shareCount'] as num?)?.toInt() ?? 1;
    final accent = isVeg ? NotionTheme.greenAccent : NotionTheme.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: NotionTheme.surfaceHover,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              s['emoji'] ?? '🍽️',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        s['name'] as String,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isVeg ? 'VEG' : 'N-VEG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: NotionTheme.surfaceHover,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        category,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    if (servingSize.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: NotionTheme.surfaceHover,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          servingSize,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (shareCount > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: NotionTheme.surfaceHover,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Serves $shareCount',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: NotionTheme.secondaryText,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _showSnackForm(existing: s),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: NotionTheme.redAccent,
                      ),
                      tooltip: 'Delete snack',
                      onPressed: () => _deleteSnack(s),
                    ),
                  ),
                ],
              ),
              Transform.scale(
                scale: 0.8,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: isActive,
                  onChanged: (_) => _toggleActive(s),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
