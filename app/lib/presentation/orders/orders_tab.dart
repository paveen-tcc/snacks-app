import 'package:flutter/material.dart';
import '../../core/di/locator.dart';
import '../../core/network/api_client.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/illustrations.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/local/app_database.dart';

/// Orders tab — the user's past orders. Renders only the body; the shell
/// provides the greeting bar + bottom nav chrome.
class OrdersTab extends StatefulWidget {
  final bool isActive;
  const OrdersTab({super.key, required this.isActive});

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

  @override
  void didUpdateWidget(covariant OrdersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load();
    }
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
            'isDefault': false,
          },
        );

        (existing['snackNames'] as List<String>).add(
          order['snackName'] as String? ?? snack?.name ?? 'Unknown',
        );
        existing['isDefault'] = (existing['isDefault'] as bool) ||
            (order['isDefaultAssigned'] ?? false);
      }

      final items = groupedItems.values.map((item) {
        final snackNames = List<String>.from(item['snackNames']);
        return {
          'date': item['date'] as String,
          'snackName': snackNames.join(', '),
          'snackNames': snackNames,
          'itemCount': snackNames.length,
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  /// Group items into sections: Today, This Week, Earlier
  _OrderSections _buildSections() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    final todayItems = <Map<String, dynamic>>[];
    final thisWeekItems = <Map<String, dynamic>>[];
    final earlierItems = <Map<String, dynamic>>[];

    for (final item in _items) {
      final dt = DateTime.parse(item['date'] as String);
      final date = DateTime(dt.year, dt.month, dt.day);
      if (date == today) {
        todayItems.add(item);
      } else if (date.isAfter(weekAgo)) {
        thisWeekItems.add(item);
      } else {
        earlierItems.add(item);
      }
    }

    return _OrderSections(
      today: todayItems,
      thisWeek: thisWeekItems,
      earlier: earlierItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_loading) {
      content = ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          AppSpacing.x5 + AppSpacing.x4,
        ),
        children: const [FoodListSkeleton()],
      );
      return content;
    } else if (_error != null) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Text('Failed to load history', style: context.text.bodyMedium),
          ),
        ],
      );
    } else if (_items.isEmpty) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
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
          ),
        ],
      );
    } else {
      final sections = _buildSections();
      content = ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          AppSpacing.x5 + AppSpacing.x4,
        ),
        children: [
          // Header
          Column(
            children: [
              const HistoryIllustration(width: 140),
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
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Sections
          if (sections.today.isNotEmpty) ...[
            _buildSectionHeader(context, 'Today'),
            const SizedBox(height: AppSpacing.sm),
            ...sections.today.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _OrderCard(item: item, dateLabel: _formatDate(item['date'] as String)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (sections.thisWeek.isNotEmpty) ...[
            _buildSectionHeader(context, 'This Week'),
            const SizedBox(height: AppSpacing.sm),
            ...sections.thisWeek.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _OrderCard(item: item, dateLabel: _formatDate(item['date'] as String)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (sections.earlier.isNotEmpty) ...[
            _buildSectionHeader(context, 'Earlier'),
            const SizedBox(height: AppSpacing.sm),
            ...sections.earlier.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _OrderCard(item: item, dateLabel: _formatDate(item['date'] as String)),
              ),
            ),
          ],
        ],
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: _load,
      child: content,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: context.text.labelMedium?.copyWith(
          color: palette.textTertiary,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _OrderSections {
  const _OrderSections({
    required this.today,
    required this.thisWeek,
    required this.earlier,
  });
  final List<Map<String, dynamic>> today;
  final List<Map<String, dynamic>> thisWeek;
  final List<Map<String, dynamic>> earlier;
}

/// A single order card with expandable item list.
class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.item, required this.dateLabel});
  final Map<String, dynamic> item;
  final String dateLabel;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: AppMotion.base,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: AppMotion.standard,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isToday = widget.dateLabel == 'Today';
    final isDefault = widget.item['isDefault'] as bool;
    final itemCount = widget.item['itemCount'] as int;
    final snackNames = List<String>.from(widget.item['snackNames'] ?? []);
    final hasMultipleItems = snackNames.length > 1;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: hasMultipleItems ? _toggleExpand : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Leading icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isToday
                          ? [
                              palette.brand.withValues(alpha: 0.15),
                              palette.brand.withValues(alpha: 0.08),
                            ]
                          : [
                              palette.surfaceMuted,
                              palette.surfaceMuted,
                            ],
                    ),
                    borderRadius: AppRadii.rSm,
                    border: Border.all(
                      color: isToday
                          ? palette.brand.withValues(alpha: 0.2)
                          : palette.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    size: 20,
                    color: isToday ? palette.brand : palette.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.item['snackName'] as String,
                              style: context.text.titleSmall?.copyWith(
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Item count chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? palette.brand.withValues(alpha: 0.12)
                                  : palette.surfaceMuted,
                              borderRadius: AppRadii.rPill,
                              border: Border.all(
                                color: isToday
                                    ? palette.brand.withValues(alpha: 0.2)
                                    : palette.border,
                              ),
                            ),
                            child: Text(
                              '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                              style: context.text.labelSmall?.copyWith(
                                color: isToday
                                    ? palette.brand
                                    : palette.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: isToday
                                ? palette.brand
                                : palette.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.dateLabel,
                            style: context.text.bodySmall?.copyWith(
                              color: isToday
                                  ? palette.brand
                                  : palette.textSecondary,
                              fontWeight:
                                  isToday ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: palette.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Default',
                              style: context.text.bodySmall?.copyWith(
                                color: palette.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasMultipleItems) ...[
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: AppMotion.base,
                    curve: AppMotion.standard,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Expandable item list
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1,
            child: Column(
              children: [
                Divider(
                  height: 1,
                  color: palette.divider,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: snackNames.asMap().entries.map((entry) {
                      final index = entry.key;
                      final name = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: palette.brand.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                name,
                                style: context.text.bodySmall?.copyWith(
                                  color: palette.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
