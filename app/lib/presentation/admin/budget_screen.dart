import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/di/locator.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/models/budget_models.dart';
import '../../data/repositories/admin_repository.dart';
import 'budget_widgets.dart';

typedef BudgetDayLoader = Future<BudgetDay> Function(String date);
typedef BudgetRangeLoader =
    Future<BudgetRange> Function({required String start, required String end});
typedef BudgetItemAdder =
    Future<void> Function(String date, Map<String, dynamic> data);
typedef BudgetItemUpdater =
    Future<void> Function(String date, String id, Map<String, dynamic> data);
typedef BudgetItemRemover = Future<void> Function(String date, String id);

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({
    super.key,
    this.isActive = true,
    this.initialDate,
    this.loadDay,
    this.loadRange,
    this.addItem,
    this.updateItem,
    this.removeItem,
  });

  final bool isActive;
  final DateTime? initialDate;
  final BudgetDayLoader? loadDay;
  final BudgetRangeLoader? loadRange;
  final BudgetItemAdder? addItem;
  final BudgetItemUpdater? updateItem;
  final BudgetItemRemover? removeItem;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  static final DateTime _reportingStartDate = DateTime(2026, 8, 1);
  static final DateTime _lastPickerDate = DateTime(9999, 12, 31);

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _shortMonths = [
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
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late DateTime _anchor;
  BudgetPeriod _period = BudgetPeriod.day;
  BudgetViewMode _viewMode = BudgetViewMode.purchases;
  BudgetTypeFilter _filter = BudgetTypeFilter.all;
  BudgetDay? _day;
  BudgetRange? _range;
  bool _loading = false;
  String? _error;
  String _searchQuery = '';
  final Set<String> _activeMutations = {};
  int _requestToken = 0;

  BudgetDayLoader get _dayLoader =>
      widget.loadDay ?? locator<AdminRepository>().getBudgetDay;
  BudgetRangeLoader get _rangeLoader =>
      widget.loadRange ?? locator<AdminRepository>().getBudgetRange;
  BudgetItemAdder get _itemAdder =>
      widget.addItem ?? locator<AdminRepository>().addBudgetItem;
  BudgetItemUpdater get _itemUpdater =>
      widget.updateItem ?? locator<AdminRepository>().updateBudgetItem;
  BudgetItemRemover get _itemRemover =>
      widget.removeItem ?? locator<AdminRepository>().removeBudgetItem;

  @override
  void initState() {
    super.initState();
    final date = widget.initialDate ?? DateTime.now();
    final normalized = DateTime(date.year, date.month, date.day);
    _anchor = normalized.isBefore(_reportingStartDate)
        ? _reportingStartDate
        : normalized;
    if (widget.isActive) _load();
  }

  @override
  void didUpdateWidget(covariant BudgetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _load();
  }

  bool get _hasCurrentData =>
      _period == BudgetPeriod.day ? _day != null : _range != null;

  Future<bool> _load({
    bool showSpinner = true,
    bool announceRefreshFailure = true,
  }) async {
    final token = ++_requestToken;
    final hadData = _hasCurrentData;
    if (mounted) {
      setState(() {
        if (showSpinner && !hadData) _loading = true;
        _error = null;
      });
    }

    try {
      if (_period == BudgetPeriod.day) {
        final day = await _dayLoader(_isoDate(_anchor));
        if (!mounted || token != _requestToken) return false;
        setState(() {
          _day = day;
          _loading = false;
          _error = null;
        });
      } else {
        final bounds = _rangeBounds;
        final range = await _rangeLoader(
          start: _isoDate(bounds.$1),
          end: _isoDate(bounds.$2),
        );
        if (!mounted || token != _requestToken) return false;
        setState(() {
          _range = range;
          _loading = false;
          _error = null;
        });
      }
      return true;
    } catch (error) {
      if (!mounted || token != _requestToken) return false;
      final message = _errorMessage(error, 'Could not load budget');
      setState(() {
        _loading = false;
        _error = message;
      });
      if (hadData && announceRefreshFailure) {
        _showMessage('$message. Pull down to retry.');
      }
      return false;
    }
  }

  (DateTime, DateTime) get _rangeBounds {
    if (_period == BudgetPeriod.week) {
      final monday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final start = monday.isBefore(_reportingStartDate)
          ? _reportingStartDate
          : monday;
      return (start, sunday);
    }
    final start = DateTime(_anchor.year, _anchor.month);
    final end = DateTime(_anchor.year, _anchor.month + 1, 0);
    return (start, end);
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DateTime _parseDate(String date) {
    final parts = date.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  void _changePeriod(BudgetPeriod period) {
    if (period == _period) return;
    setState(() {
      _period = period;
      _error = null;
      _searchQuery = '';
      if (period == BudgetPeriod.day) {
        _day = null;
      } else {
        _range = null;
      }
    });
    _load();
  }

  void _movePeriod(int direction) {
    if (direction < 0 && !_canMovePrevious) return;
    setState(() {
      final moved = switch (_period) {
        BudgetPeriod.day => _anchor.add(Duration(days: direction)),
        BudgetPeriod.week => _anchor.add(Duration(days: 7 * direction)),
        BudgetPeriod.month => DateTime(
          _anchor.year,
          _anchor.month + direction,
          1,
        ),
      };
      _anchor = moved.isBefore(_reportingStartDate)
          ? _reportingStartDate
          : moved;
      if (_period == BudgetPeriod.day) {
        _day = null;
      } else {
        _range = null;
      }
      _error = null;
      _searchQuery = '';
    });
    _load();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: _reportingStartDate,
      lastDate: _lastPickerDate,
      helpText: 'Select budget date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _anchor = picked;
      if (_period == BudgetPeriod.day) {
        _day = null;
      } else {
        _range = null;
      }
      _error = null;
      _searchQuery = '';
    });
    _load();
  }

  bool get _canMovePrevious => switch (_period) {
    BudgetPeriod.day => _anchor.isAfter(_reportingStartDate),
    BudgetPeriod.week => _rangeBounds.$1.isAfter(_reportingStartDate),
    BudgetPeriod.month => DateTime(
      _anchor.year,
      _anchor.month,
    ).isAfter(_reportingStartDate),
  };

  void _openDay(String date) {
    setState(() {
      _anchor = _parseDate(date);
      _period = BudgetPeriod.day;
      _day = null;
      _error = null;
      _searchQuery = '';
    });
    _load();
  }

  String get _periodLabel {
    if (_period == BudgetPeriod.day) {
      return '${_weekdays[_anchor.weekday - 1]}, '
          '${_shortMonths[_anchor.month - 1]} ${_anchor.day}';
    }
    if (_period == BudgetPeriod.week) {
      final bounds = _rangeBounds;
      final start = bounds.$1;
      final end = bounds.$2;
      return '${_shortMonths[start.month - 1]} ${start.day} – '
          '${_shortMonths[end.month - 1]} ${end.day}';
    }
    return '${_months[_anchor.month - 1]} ${_anchor.year}';
  }

  String _dayLabel(String date) {
    final parsed = _parseDate(date);
    if (_period == BudgetPeriod.week) {
      return '${_weekdays[parsed.weekday - 1]} ${parsed.day}';
    }
    return '${_shortMonths[parsed.month - 1]} ${parsed.day}';
  }

  Future<void> _editItem(BudgetLine? line) async {
    await showBudgetItemSheet(
      context: context,
      line: line,
      onSave: (data) async {
        final key = line == null ? 'add' : 'edit:${line.id}';
        final success = line == null ? 'Item added' : 'Item updated';
        await _performMutation(
          key: key,
          action: () => line == null
              ? _itemAdder(_isoDate(_anchor), data)
              : _itemUpdater(_isoDate(_anchor), line.id, data),
          successMessage: success,
        );
      },
    );
  }

  Future<void> _confirmRemove(BudgetLine line) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove purchase item?'),
        content: Text(
          '${line.name} will no longer count toward this day’s budget.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _performMutation(
        key: 'remove:${line.id}',
        action: () => _itemRemover(_isoDate(_anchor), line.id),
        successMessage: 'Item removed',
      );
    } catch (_) {
      // _performMutation already presents the actionable failure.
    }
  }

  Future<void> _performMutation({
    required String key,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_activeMutations.contains(key)) return;
    setState(() => _activeMutations.add(key));
    try {
      await action();
      final refreshed = await _load(
        showSpinner: false,
        announceRefreshFailure: false,
      );
      if (!mounted) return;
      _showMessage(
        refreshed
            ? successMessage
            : '$successMessage, but refresh failed. Pull down to retry.',
      );
    } catch (error) {
      final message = _errorMessage(error, 'Could not save budget item');
      if (mounted) _showMessage('$message. Try again.');
      throw Exception(message);
    } finally {
      if (mounted) setState(() => _activeMutations.remove(key));
    }
  }

  String _errorMessage(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      if (error.message?.trim().isNotEmpty == true) {
        return error.message!.trim();
      }
    }
    return fallback;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Budget',
                  style: context.text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh budget',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _loading ? null : () => _load(),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && !_hasCurrentData) return const _BudgetLoading();
    if (_error != null && !_hasCurrentData) {
      return _BudgetError(message: _error!, onRetry: _load);
    }

    final totals = _period == BudgetPeriod.day
        ? _day?.totals ?? BudgetTotals.zero
        : _range?.totals ?? BudgetTotals.zero;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          120,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BudgetPeriodControl(value: _period, onChanged: _changePeriod),
                  const SizedBox(height: AppSpacing.md),
                  _DateNavigator(
                    label: _periodLabel,
                    onPrevious: _canMovePrevious ? () => _movePeriod(-1) : null,
                    onNext: () => _movePeriod(1),
                    onCalendar: _pickDate,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BudgetViewModeControl(
                    value: _viewMode,
                    onChanged: (mode) => setState(() => _viewMode = mode),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  BudgetSummaryCards(totals: totals),
                  const SizedBox(height: AppSpacing.xl),
                  BudgetTypeControl(
                    value: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_viewMode == BudgetViewMode.people)
                    _buildPeopleContent()
                  else if (_period == BudgetPeriod.day)
                    _buildDayContent()
                  else
                    _buildRangeContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleContent() {
    final query = _searchQuery.trim().toLowerCase();
    final allSpendings = _period == BudgetPeriod.day
        ? (_day?.userSpendings ?? const <UserSpending>[])
        : (_range?.userSpendings ?? const <UserSpending>[]);

    final filteredSpendings = allSpendings
        .where((user) {
          if (query.isEmpty) return true;
          final matchesUser = user.username.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
          final matchesItem = user.items.any(
            (item) => item.name.toLowerCase().contains(query),
          );
          return matchesUser || matchesItem;
        })
        .where((user) => user.amountForFilter(_filter) > 0)
        .toList();

    final maxAmount = filteredSpendings.fold<int>(
      0,
      (highest, user) => user.amountForFilter(_filter) > highest
          ? user.amountForFilter(_filter)
          : highest,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserSpendingStatsCard(
          userSpendings: allSpendings,
          filter: _filter,
        ),
        const SizedBox(height: AppSpacing.xl),
        BudgetSearchField(
          query: _searchQuery,
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionHeading(
          title: 'Per-person spending ranking',
          subtitle:
              '${filteredSpendings.length} ${filteredSpendings.length == 1 ? 'person' : 'people'} in this view',
        ),
        const SizedBox(height: AppSpacing.sm),
        _SectionCard(
          child: filteredSpendings.isEmpty
              ? const _BudgetEmpty(
                  icon: Icons.people_outline_rounded,
                  title: 'No spending recorded',
                  message: 'No employee orders found for this selection.',
                )
              : Column(
                  children: [
                    for (var index = 0;
                        index < filteredSpendings.length;
                        index++) ...[
                      UserSpendingRow(
                        user: filteredSpendings[index],
                        rank: index + 1,
                        filter: _filter,
                        maxAmount: maxAmount,
                        onTap: () => showUserSpendingSheet(
                          context: context,
                          user: filteredSpendings[index],
                          filter: _filter,
                          periodLabel: _periodLabel,
                        ),
                      ),
                      if (index != filteredSpendings.length - 1)
                        const Divider(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDayContent() {
    final query = _searchQuery.trim().toLowerCase();
    final lines = (_day?.items ?? const <BudgetLine>[])
        .where((line) => _filter.includes(line.itemType))
        .where((line) => query.isEmpty || line.name.toLowerCase().contains(query))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BudgetSearchField(
          query: _searchQuery,
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SectionHeading(
                title: 'Purchase lines',
                subtitle: '${lines.length} visible',
              ),
            ),
            SizedBox(
              width: 176,
              child: SecondaryButton(
                key: const Key('budget-add-item'),
                label: 'Add custom item',
                icon: Icons.add_rounded,
                onPressed: !_activeMutations.contains('add')
                    ? () => _editItem(null)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (lines.isEmpty)
          const _BudgetEmpty(
            icon: Icons.shopping_basket_outlined,
            title: 'No purchases in this view',
            message: 'Add a custom item or choose another item type.',
          )
        else
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: BudgetPurchaseLineCard(
                line: line,
                isBusy:
                    _activeMutations.contains('edit:${line.id}') ||
                    _activeMutations.contains('remove:${line.id}'),
                onEdit:
                    !_activeMutations.contains('edit:${line.id}') &&
                        !_activeMutations.contains('remove:${line.id}')
                    ? () => _editItem(line)
                    : null,
                onRemove:
                    !_activeMutations.contains('edit:${line.id}') &&
                        !_activeMutations.contains('remove:${line.id}')
                    ? () => _confirmRemove(line)
                    : null,
              ),
            ),
      ],
    );
  }

  Widget _buildRangeContent() {
    final days = _range?.days ?? const <BudgetDay>[];
    final items = (_range?.items ?? const <BudgetItemTotal>[])
        .where((item) => _filter.includes(item.itemType))
        .toList();
    final maxAmount = days.fold<int>(
      0,
      (highest, day) => _filter.amountFrom(day.totals) > highest
          ? _filter.amountFrom(day.totals)
          : highest,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Daily spend',
          subtitle: 'Tap a day to edit purchases',
        ),
        const SizedBox(height: AppSpacing.sm),
        _SectionCard(
          child: days.isEmpty
              ? const _BudgetEmpty(
                  icon: Icons.calendar_today_outlined,
                  title: 'No daily totals yet',
                  message: 'Pull down to refresh this period.',
                )
              : Column(
                  children: [
                    for (var index = 0; index < days.length; index++) ...[
                      BudgetDailyTotalRow(
                        day: days[index],
                        filter: _filter,
                        maxAmount: maxAmount,
                        label: _dayLabel(days[index].date),
                        onTap: () => _openDay(days[index].date),
                      ),
                      if (index != days.length - 1) const Divider(),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const _SectionHeading(
          title: 'Item totals',
          subtitle: 'Combined across the selected period',
        ),
        const SizedBox(height: AppSpacing.sm),
        _SectionCard(
          child: items.isEmpty
              ? const _BudgetEmpty(
                  icon: Icons.receipt_long_outlined,
                  title: 'No item totals in this view',
                  message: 'Choose another item type or period.',
                )
              : Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      BudgetItemTotalRow(item: items[index]),
                      if (index != items.length - 1) const Divider(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onCalendar,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous period',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: onCalendar,
              icon: const Icon(Icons.calendar_month_outlined, size: 19),
              label: Text(label, textAlign: TextAlign.center),
            ),
          ),
          IconButton(
            tooltip: 'Next period',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleMedium),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: context.text.bodySmall?.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: context.palette.border),
        boxShadow: context.shadows.sm,
      ),
      child: child,
    );
  }
}

class _BudgetEmpty extends StatelessWidget {
  const _BudgetEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 34, color: palette.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetLoading extends StatelessWidget {
  const _BudgetLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: const [
        Skeleton(height: 44, borderRadius: AppRadii.rPill),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 56, borderRadius: AppRadii.rLg),
        SizedBox(height: AppSpacing.xl),
        Skeleton(height: 104, borderRadius: AppRadii.rLg),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: Skeleton(height: 88, borderRadius: AppRadii.rLg)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Skeleton(height: 88, borderRadius: AppRadii.rLg)),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        Skeleton(height: 44, borderRadius: AppRadii.rPill),
        SizedBox(height: AppSpacing.xl),
        Skeleton(height: 108, borderRadius: AppRadii.rLg),
      ],
    );
  }
}

class _BudgetError extends StatelessWidget {
  const _BudgetError({required this.message, required this.onRetry});

  final String message;
  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: context.palette.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Budget unavailable', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
