import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/di/locator.dart';
import '../../core/theme/notion_theme.dart';
import '../../core/widgets/illustrations.dart';
import '../../data/repositories/admin_repository.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _loading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await locator<AdminRepository>().getSummary();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendWhatsApp() async {
    if (_data == null) return;
    final orders = List<Map<String, dynamic>>.from(_data!['orders']);
    final drinks = List<Map<String, dynamic>>.from(_data!['drinks']);
    final total = _data!['totalOrders'] as int;
    final date = _data!['date'] as String;

    final buf = StringBuffer();
    buf.writeln('🍿 *Snack Order — $date*');
    buf.writeln('━━━━━━━━━━━━━━━');
    for (final o in orders) {
      buf.writeln('${o['snackEmoji'] ?? '•'} ${o['snackName']}: ${o['count']}');
    }
    buf.writeln('━━━━━━━━━━━━━━━');
    buf.writeln('*Total: $total*');
    if (drinks.isNotEmpty) {
      final maxVotes = drinks
          .map((drink) => (drink['count'] as num?)?.toInt() ?? 0)
          .fold<int>(0, (maxValue, count) => count > maxValue ? count : maxValue);
      final topDrinks = drinks
          .where((drink) => ((drink['count'] as num?)?.toInt() ?? 0) == maxVotes)
          .toList();
      buf.writeln('');
      buf.writeln(topDrinks.length > 1 ? '☕ *Top Hot Drinks*' : '☕ *Top Hot Drink*');
      for (final d in topDrinks) {
        buf.writeln('${d['drinkEmoji'] ?? '•'} ${d['drinkName']}');
      }
    }

    final settings = await locator<AdminRepository>().getSettings();
    final number = settings['whatsapp_number'] ?? '';
    final encoded = Uri.encodeComponent(buf.toString());
    final uri = Uri.parse('https://wa.me/$number?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Summary"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: FoodLoader())
          : _data == null
              ? const Center(child: Text('Failed to load summary'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Date: ${_data!['date']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    _buildSection(context, 'Snack Orders', [
                      ...List<Map<String, dynamic>>.from(_data!['orders']).map((o) =>
                        _buildCountRow(context, '${o['snackEmoji'] ?? '🍽️'} ${o['snackName']}', o['count'].toString()),
                      ),
                      const Divider(),
                      _buildCountRow(context, 'Total', _data!['totalOrders'].toString(), bold: true),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Hot Drink Poll', [
                      ...List<Map<String, dynamic>>.from(_data!['drinks']).map((d) =>
                        _buildCountRow(context, '${d['drinkEmoji'] ?? '☕'} ${d['drinkName']}', d['count'].toString()),
                      ),
                      if ((_data!['drinks'] as List).isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('No votes yet', style: Theme.of(context).textTheme.bodySmall),
                        ),
                    ]),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _sendWhatsApp,
                      icon: const Text('📱'),
                      label: const Text('Send to WhatsApp'),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(border: Border.all(color: NotionTheme.border), borderRadius: BorderRadius.circular(8)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildCountRow(BuildContext context, String label, String count, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: bold ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(count, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
