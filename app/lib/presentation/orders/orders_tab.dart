import 'package:flutter/material.dart';
import '../../core/di/locator.dart';
import '../../core/network/api_client.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/illustrations.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/food_card.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/order_repository.dart';
import '../home/home_helpers.dart';

/// Suffix the server/app append to a drink's stored name when it's sugar-free.
const String _sugarFreeSuffix = ' (Sugar Free)';

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

  /// Date key of the order currently being re-placed, for per-card spinners.
  String? _reorderingDate;

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

  Future<void> _load({bool isRefresh = false}) async {
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
            'lines': <Map<String, dynamic>>[],
            'isDefault': false,
          },
        );

        final lineName = order['snackName'] as String? ?? snack?.name;
        (existing['snackNames'] as List<String>).add(lineName ?? 'Unknown');
        // The server bakes " (Sugar Free)" into the stored name; strip it for
        // the base name (used for re-resolution) but remember the flag so a
        // reorder stays sugar-free.
        final isSugarFree =
            lineName != null && lineName.endsWith(_sugarFreeSuffix);
        final baseName = isSugarFree
            ? lineName.substring(0, lineName.length - _sugarFreeSuffix.length)
            : lineName;
        final isVeg = (order['isVeg'] as bool?) ?? snack?.isVeg ?? true;
        // One entry per ordered unit so quantity survives a reorder; keep the
        // name too so a snack whose id changed (e.g. the drinks migration) can
        // still be re-resolved by name at reorder time.
        (existing['lines'] as List<Map<String, dynamic>>).add({
          'id': snackId,
          'name': baseName,
          'isVeg': isVeg,
          'sugarFree': isSugarFree,
        });
        existing['isDefault'] = (existing['isDefault'] as bool) ||
            (order['isDefaultAssigned'] ?? false);
      }

      final items = groupedItems.values.map((item) {
        final snackNames = List<String>.from(item['snackNames']);
        final lines = List<Map<String, dynamic>>.from(item['lines']);

        // Group identical lines together for clean "N x Name" list presentation
        final groupedLinesMap = <String, Map<String, dynamic>>{};
        for (final line in lines) {
          final name = line['name'] as String;
          final isVeg = line['isVeg'] as bool? ?? true;
          final sugarFree = line['sugarFree'] as bool? ?? false;
          final key = '$name-$isVeg-$sugarFree';
          if (groupedLinesMap.containsKey(key)) {
            groupedLinesMap[key]!['quantity'] =
                (groupedLinesMap[key]!['quantity'] as int) + 1;
          } else {
            groupedLinesMap[key] = {
              'id': line['id'],
              'name': name,
              'isVeg': isVeg,
              'sugarFree': sugarFree,
              'quantity': 1,
            };
          }
        }

        return {
          'date': item['date'] as String,
          'snackName': snackNames.join(', '),
          'snackNames': snackNames,
          'lines': lines,
          'groupedLines': groupedLinesMap.values.toList(),
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
      // A failed background refresh (e.g. right after a reorder while offline)
      // must not wipe the list we're already showing.
      if (isRefresh) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Reads cached public settings to mirror the home tab's ordering window
  /// gate (cutoff time, or the advance-order window when enabled).
  Future<bool> _isOrderingClosed(AppDatabase db) async {
    final settings = await (db.select(db.localSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (settings?.advanceOrderMode == true) {
      return !isWithinTimeRange(
        settings?.advanceWindowStart ?? '06:00',
        settings?.advanceWindowEnd ?? '22:00',
      );
    }
    return hasCutoffPassed(settings?.cutoffTime ?? '12:00');
  }

  /// Re-places a past order's items as today's order. Each historical line is
  /// resolved to a currently-active snack — by id first, then by name (so a
  /// snack whose id changed still reorders) — unavailable items are skipped,
  /// and quantity (duplicate lines) is preserved.
  Future<void> _reorder(Map<String, dynamic> item) async {
    if (_reorderingDate != null) return; // one reorder at a time
    // Claim the busy state synchronously so a fast double-tap can't slip past
    // the guard during the awaits below.
    setState(() => _reorderingDate = item['date'] as String);
    try {
      final db = locator<AppDatabase>();

      if (await _isOrderingClosed(db)) {
        _showSnack('Ordering is closed for today.');
        return;
      }

      final lines = List<Map<String, dynamic>>.from(
        item['lines'] ?? const <Map<String, dynamic>>[],
      );
      if (lines.isEmpty) {
        _showSnack('Nothing to reorder.');
        return;
      }

      // Resolve against the live active catalog, freshly queried.
      final activeSnacks = await (db.select(db.localSnacks)
            ..where((t) => t.isActive.equals(true)))
          .get();
      final byId = {for (final s in activeSnacks) s.id: s};
      final byName = <String, LocalSnack>{};
      for (final s in activeSnacks) {
        byName.putIfAbsent(_normalizeName(s.name), () => s);
      }

      final resolvedIds = <String>[];
      final sugarFreePrefs = <String, bool>{};
      var unavailable = 0;
      for (final line in lines) {
        final id = line['id'] as String?;
        final name = line['name'] as String?;
        final match = (id != null ? byId[id] : null) ??
            (name != null ? byName[_normalizeName(name)] : null);
        if (match != null) {
          resolvedIds.add(match.id);
          if (line['sugarFree'] == true) sugarFreePrefs[match.id] = true;
        } else {
          unavailable++;
        }
      }

      if (resolvedIds.isEmpty) {
        _showSnack('These items are no longer available to order.');
        return;
      }

      await locator<OrderRepository>().placeOrder(
        resolvedIds,
        sugarFreePrefs: sugarFreePrefs,
      );
      if (!mounted) return;
      _showSnack(
        unavailable > 0
            ? 'Reordered ${resolvedIds.length} of ${lines.length} items '
                  '($unavailable no longer available).'
            : 'Reordered successfully.',
      );
      await _load(isRefresh: true);
    } catch (_) {
      if (mounted) _showSnack('Could not reorder. Please try again.');
    } finally {
      if (mounted) setState(() => _reorderingDate = null);
    }
  }

  String _normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.x5 + AppSpacing.x4,
        ),
        children: const [FoodListSkeleton()],
      );
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
        key: const PageStorageKey('orders_tab_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          120,
        ),
        children: [
          // Sections
          if (sections.today.isNotEmpty) ...[
            _buildSectionHeader(context, 'Today'),
            const SizedBox(height: AppSpacing.xs),
            ...sections.today.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _OrderCard(
                  item: item,
                  dateLabel: _formatDate(item['date'] as String),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (sections.thisWeek.isNotEmpty) ...[
            _buildSectionHeader(context, 'This Week'),
            const SizedBox(height: AppSpacing.xs),
            ...sections.thisWeek.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _OrderCard(
                  item: item,
                  dateLabel: _formatDate(item['date'] as String),
                  onReorder: () => _reorder(item),
                  isReordering: _reorderingDate == item['date'],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (sections.earlier.isNotEmpty) ...[
            _buildSectionHeader(context, 'Earlier'),
            const SizedBox(height: AppSpacing.xs),
            ...sections.earlier.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _OrderCard(
                  item: item,
                  dateLabel: _formatDate(item['date'] as String),
                  onReorder: () => _reorder(item),
                  isReordering: _reorderingDate == item['date'],
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            alignment: Alignment.centerLeft,
            child: Text(
              'Orders',
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator.adaptive(
              onRefresh: _load,
              child: content,
            ),
          ),
        ],
      ),
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

/// A single order card showing items listed compactly with low vertical footprint.
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.item,
    required this.dateLabel,
    this.onReorder,
    this.isReordering = false,
  });

  final Map<String, dynamic> item;
  final String dateLabel;
  final VoidCallback? onReorder;
  final bool isReordering;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isToday = dateLabel == 'Today';
    final isDefault = item['isDefault'] as bool;
    final groupedLines = List<Map<String, dynamic>>.from(
      item['groupedLines'] ?? const <Map<String, dynamic>>[],
    );

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header: Date + Default badge on left, Compact Reorder action on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: isToday ? palette.brand : palette.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateLabel,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                      color: isToday ? palette.brand : palette.textPrimary,
                      fontSize: 12.5,
                    ),
                  ),
                  if (isDefault) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: AppRadii.rPill,
                        border: Border.all(color: palette.border),
                      ),
                      child: Text(
                        'Default',
                        style: context.text.labelSmall?.copyWith(
                          color: palette.textTertiary,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (onReorder != null)
                _CompactReorderButton(
                  label: isReordering ? 'Reordering…' : 'Reorder',
                  isLoading: isReordering,
                  onPressed: isReordering ? null : onReorder,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: palette.divider),
          ),
          // Items listed one by one: [VegBadge] [quantity] x [Item Name]
          for (final line in groupedLines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  VegBadge(isVeg: line['isVeg'] as bool? ?? true, size: 13),
                  const SizedBox(width: 7),
                  Text(
                    '${line['quantity']} x ',
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                      fontSize: 12.5,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${line['name']}${line['sugarFree'] == true ? ' (Sugar Free)' : ''}',
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                        fontSize: 12.5,
                      ),
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

/// Compact tactile reorder button with low vertical height.
class _CompactReorderButton extends StatelessWidget {
  const _CompactReorderButton({
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onPressed != null;

    return PressableScale(
      onTap: onPressed,
      scale: 0.95,
      child: Container(
        height: 25,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: enabled
              ? palette.brand.withValues(alpha: 0.08)
              : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? palette.brand.withValues(alpha: 0.35)
                : palette.border,
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: palette.brand,
                ),
              )
            else
              Icon(
                Icons.replay_rounded,
                size: 13,
                color: enabled ? palette.brand : palette.textTertiary,
              ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: enabled ? palette.brand : palette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
