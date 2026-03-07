import 'package:flutter/material.dart';
import '../../core/di/locator.dart';
import '../../core/theme/notion_theme.dart';
import '../../data/repositories/admin_repository.dart';

class AdminSnacksScreen extends StatefulWidget {
  const AdminSnacksScreen({super.key});

  @override
  State<AdminSnacksScreen> createState() => _AdminSnacksScreenState();
}

class _AdminSnacksScreenState extends State<AdminSnacksScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _snacks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snacks = await locator<AdminRepository>().getAllSnacks();
      setState(() { _snacks = snacks; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> snack) async {
    final newVal = !(snack['isActive'] as bool? ?? true);
    try {
      await locator<AdminRepository>().updateSnack(snack['id'] as String, {'isActive': newVal});
      await _load();
    } catch (e) {
      _showError('Failed to update snack');
    }
  }

  Future<void> _setDefault(Map<String, dynamic> snack) async {
    try {
      await locator<AdminRepository>().updateSnack(snack['id'] as String, {'isDefault': true});
      await _load();
    } catch (e) {
      _showError('Failed to set default');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSnackForm({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final emojiCtrl = TextEditingController(text: existing?['emoji'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final sizeCtrl = TextEditingController(text: existing?['servingSize'] ?? '');
    bool isVeg = existing?['isVeg'] ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'Add Snack' : 'Edit Snack',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *'))),
                const SizedBox(width: 12),
                SizedBox(width: 80, child: TextField(controller: emojiCtrl, decoration: const InputDecoration(labelText: 'Emoji'))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Short description')),
              const SizedBox(height: 12),
              TextField(controller: sizeCtrl, decoration: const InputDecoration(labelText: 'Serving size (e.g. 2 Pcs)')),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Veg'),
                Switch(value: isVeg, onChanged: (v) => setModalState(() => isVeg = v)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final data = {
                      'name': nameCtrl.text.trim(),
                      'emoji': emojiCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'servingSize': sizeCtrl.text.trim(),
                      'isVeg': isVeg,
                    };
                    Navigator.pop(ctx);
                    if (existing != null) {
                      await locator<AdminRepository>().updateSnack(existing['id'] as String, data);
                    } else {
                      await locator<AdminRepository>().addSnack({...data, 'isActive': true, 'isDefault': false, 'sortOrder': _snacks.length});
                    }
                    await _load();
                  },
                  child: Text(existing == null ? 'Add Snack' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Snacks'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSnackForm(),
        backgroundColor: NotionTheme.primaryText,
        child: const Icon(Icons.add, color: NotionTheme.background),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: NotionTheme.primaryText))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _snacks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = _snacks[i];
                final isActive = s['isActive'] as bool? ?? true;
                final isDefault = s['isDefault'] as bool? ?? false;
                final isVeg = s['isVeg'] as bool? ?? true;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(s['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 28)),
                  title: Row(children: [
                    Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 14, color: NotionTheme.yellowAccent),
                    ],
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isVeg ? NotionTheme.greenAccent.withOpacity(0.1) : NotionTheme.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(isVeg ? 'VEG' : 'N-VEG',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                              color: isVeg ? NotionTheme.greenAccent : NotionTheme.redAccent)),
                    ),
                  ]),
                  subtitle: Text(s['servingSize'] ?? '', style: Theme.of(context).textTheme.bodySmall),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isDefault)
                        IconButton(
                          icon: const Icon(Icons.star_border, size: 20),
                          tooltip: 'Set as default',
                          onPressed: () => _setDefault(s),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showSnackForm(existing: s),
                      ),
                      Switch(
                        value: isActive,
                        onChanged: (_) => _toggleActive(s),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
