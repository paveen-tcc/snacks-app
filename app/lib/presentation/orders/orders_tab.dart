import 'package:flutter/material.dart';
import '../../core/di/locator.dart';
import '../../core/network/api_client.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/illustrations.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/local/app_database.dart';

/// Orders tab — the user's past orders (formerly the History screen). Renders
/// only the body; the shell provides the greeting bar + bottom nav chrome.
class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
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
        final snackId = order['snackId'] as String?;
        final snack = snackId != null ? snackMap[snackId] : null;
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

        (existing['snackNames'] as List<String>).add(
          order['snackName'] as String? ?? snack?.name ?? 'Unknown',
        );
        (existing['snackEmojis'] as List<String>).add(
          order['snackEmoji'] as String? ?? snack?.emoji ?? '🍽️',
        );
        existing['isDefault'] = (existing['isDefault'] as bool) ||
            (order['isDefaultAssigned'] ?? false);
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
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          AppSpacing.x5 + AppSpacing.x4,
        ),
        children: const [FoodListSkeleton()],
      );
    }
    if (_error != null) {
      return Center(
        child: Text('Failed to load history', style: context.text.bodyMedium),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyStateIllustration(emoji: '🍽️', size: 130),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No order history yet',
              style: context.text.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your orders will appear here',
              style: context.text.bodySmall?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          AppSpacing.x5 + AppSpacing.x4,
        ),
        itemCount: _items.length + 1,
        separatorBuilder: (_, index) => index == 0
            ? const SizedBox(height: AppSpacing.lg)
            : const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                const HistoryIllustration(width: 160),
                const SizedBox(height: AppSpacing.sm),
                Text('Your Orders', style: context.text.titleLarge),
                const SizedBox(height: 2),
                Text(
                  '${_items.length} order${_items.length == 1 ? '' : 's'}',
                  style: context.text.bodySmall?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            );
          }
          return _buildOrderCard(_items[index - 1]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> item) {
    final palette = context.palette;
    final dateLabel = _formatDate(item['date'] as String);
    final isToday = dateLabel == 'Today';
    final isDefault = item['isDefault'] as bool;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadii.rMd,
              border: Border.all(color: palette.border),
            ),
            alignment: Alignment.center,
            child: Text(
              item['snackEmoji'] as String,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['snackName'] as String, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: context.text.bodySmall?.copyWith(
                    color: isToday ? palette.brand : palette.textSecondary,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadii.rPill,
                border: Border.all(color: palette.border),
              ),
              child: Text('Default', style: context.text.labelSmall),
            ),
        ],
      ),
    );
  }
}
