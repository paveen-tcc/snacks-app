import 'package:flutter/material.dart';
import '../../core/di/locator.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/notion_theme.dart';
import '../../core/widgets/illustrations.dart';
import '../../data/local/app_database.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = locator<ApiClient>();
      final db = locator<AppDatabase>();

      final results = await Future.wait([
        api.dio.get('/orders/history'),
        db.select(db.localSnacks).get(),
      ]);

      final historyRes = results[0] as dynamic;
      final history = List<Map<String, dynamic>>.from(
        historyRes.data['history'],
      );
      final snacks = results[1] as List<LocalSnack>;
      final snackMap = {for (final s in snacks) s.id: s};

      final groupedItems = <String, Map<String, dynamic>>{};
      for (final order in history) {
        final snack = snackMap[order['snackId'] as String];
        final date = order['date'] as String;
        final existing = groupedItems.putIfAbsent(
          date,
          () => {
            'date': date,
            'snackNames': <String>[],
            'snackEmojis': <String>[],
            'isDefault': false,
          },
        );

        (existing['snackNames'] as List<String>).add(snack?.name ?? 'Unknown');
        (existing['snackEmojis'] as List<String>).add(snack?.emoji ?? '🍽️');
        existing['isDefault'] =
            (existing['isDefault'] as bool) || (order['isDefaultAssigned'] ?? false);
      }

      final items = groupedItems.values.map((item) {
        final snackNames = List<String>.from(item['snackNames']);
        final snackEmojis = List<String>.from(item['snackEmojis']);
        final emojiLabel = snackEmojis.take(3).join(' ');
        return {
          'date': item['date'] as String,
          'snackName': snackNames.join(', '),
          'snackEmoji': snackEmojis.length > 3 ? '$emojiLabel +' : emojiLabel,
          'isDefault': item['isDefault'] as bool,
        };
      }).toList();

      // Sort newest first
      items.sort(
        (a, b) => (b['date'] as String).compareTo(a['date'] as String),
      );

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: FoodLoader())
          : _error != null
          ? Center(
              child: Text(
                'Failed to load history',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyStateIllustration(emoji: '🍽️', size: 130),
                  const SizedBox(height: 20),
                  Text(
                    'No order history yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your orders will appear here',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length + 1,
              separatorBuilder: (_, index) =>
                  index == 0 ? const SizedBox.shrink() : const Divider(),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        const HistoryIllustration(width: 160),
                        const SizedBox(height: 8),
                        Text(
                          'Your Orders',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_items.length} order${_items.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }
                final item = _items[index - 1];
                final dateLabel = _formatDate(item['date'] as String);
                final isToday = dateLabel == 'Today';
                final isDefault = item['isDefault'] as bool;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    item['snackEmoji'] as String,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    item['snackName'] as String,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isToday
                          ? NotionTheme.blueAccent
                          : NotionTheme.secondaryText,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isDefault
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NotionTheme.surfaceHover,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(fontSize: 11),
                          ),
                        )
                      : null,
                );
              },
            ),
    );
  }
}
