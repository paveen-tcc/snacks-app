import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/di/locator.dart';
import '../../core/formatters/rupees.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_app_bar.dart';
import '../../data/models/budget_models.dart';
import '../../data/repositories/admin_repository.dart';

typedef BudgetRangeLoader =
    Future<BudgetRange> Function({required String start, required String end});

/// Lets an admin pick a month and generates a WhatsApp-pastable text report:
/// per-day purchase lines with price and a day total, weekly subtotals, and
/// a final month total.
class BudgetExportScreen extends StatefulWidget {
  const BudgetExportScreen({super.key, this.initialMonth, this.loadRange});

  final DateTime? initialMonth;
  final BudgetRangeLoader? loadRange;

  @override
  State<BudgetExportScreen> createState() => _BudgetExportScreenState();
}

class _BudgetExportScreenState extends State<BudgetExportScreen> {
  static final DateTime _reportingStart = DateTime(2026, 8, 1);

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late DateTime _month;
  BudgetRange? _range;
  bool _loading = false;
  String? _error;

  BudgetRangeLoader get _rangeLoader =>
      widget.loadRange ?? locator<AdminRepository>().getBudgetRange;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth ?? DateTime.now();
    _month = _clampMonth(DateTime(initial.year, initial.month));
    _load();
  }

  DateTime _clampMonth(DateTime month) {
    final reportingMonth = DateTime(_reportingStart.year, _reportingStart.month);
    return month.isBefore(reportingMonth) ? reportingMonth : month;
  }

  bool get _canGoPrevious =>
      DateTime(_month.year, _month.month - 1).isAfter(
        DateTime(_reportingStart.year, _reportingStart.month - 1),
      );

  void _changeMonth(int direction) {
    setState(() {
      _month = _clampMonth(DateTime(_month.year, _month.month + direction));
      _range = null;
      _error = null;
    });
    _load();
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final start = DateTime(_month.year, _month.month, 1);
      final end = DateTime(_month.year, _month.month + 1, 0);
      final range = await _rangeLoader(
        start: _isoDate(start),
        end: _isoDate(end),
      );
      if (!mounted) return;
      setState(() {
        _range = range;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load budget for this month';
        _loading = false;
      });
    }
  }

  DateTime _parseDate(String date) {
    final parts = date.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  /// Buckets days into Monday–Sunday weeks. Since [days] only spans the
  /// selected month, the first/last bucket may be a partial week.
  List<List<BudgetDay>> _weeksFrom(List<BudgetDay> days) {
    final weeks = <List<BudgetDay>>[];
    var current = <BudgetDay>[];
    for (final day in days) {
      final date = _parseDate(day.date);
      if (current.isNotEmpty && date.weekday == DateTime.monday) {
        weeks.add(current);
        current = [];
      }
      current.add(day);
    }
    if (current.isNotEmpty) weeks.add(current);
    return weeks;
  }

  String _buildReportText(BudgetRange range) {
    final days = List<BudgetDay>.from(range.days)
      ..sort((a, b) => a.date.compareTo(b.date));
    final buf = StringBuffer();
    buf.writeln('*Budget report — ${_months[_month.month - 1]} ${_month.year}*');
    buf.writeln();

    if (days.isEmpty) {
      buf.writeln('No purchases recorded this month.');
      return buf.toString().trimRight();
    }

    for (final week in _weeksFrom(days)) {
      for (final day in week) {
        final date = _parseDate(day.date);
        buf.writeln(
          '*${_weekdays[date.weekday - 1]}, '
          '${_shortMonths[date.month - 1]} ${date.day}*',
        );
        if (day.items.isEmpty) {
          buf.writeln('No purchases');
        } else {
          for (final item in day.items) {
            buf.writeln(
              '${item.name} x${item.quantity} @ '
              '${formatRupees(item.unitPriceRupees)} = '
              '${formatRupees(item.lineTotalRupees)}',
            );
          }
        }
        buf.writeln('Day total: ${formatRupees(day.totals.total)}');
        buf.writeln();
      }

      final weekTotal = week.fold<int>(0, (sum, day) => sum + day.totals.total);
      final weekStart = _parseDate(week.first.date);
      final weekEnd = _parseDate(week.last.date);
      buf.writeln(
        'Week total (${_shortMonths[weekStart.month - 1]} ${weekStart.day} - '
        '${_shortMonths[weekEnd.month - 1]} ${weekEnd.day}): '
        '${formatRupees(weekTotal)}',
      );
      buf.writeln('—————');
      buf.writeln();
    }

    buf.writeln('*Final total: ${formatRupees(range.totals.total)}*');
    return buf.toString().trimRight();
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final range = _range;
    final reportText = range != null ? _buildReportText(range) : null;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: const GlassAppBar(title: 'Export budget report'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              0,
            ),
            child: _MonthNavigator(
              label: '${_months[_month.month - 1]} ${_month.year}',
              onPrevious: _canGoPrevious ? () => _changeMonth(-1) : null,
              onNext: () => _changeMonth(1),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.md),
                          PrimaryButton(
                            label: 'Try again',
                            fullWidth: false,
                            onPressed: _load,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: AppRadii.rLg,
                          border: Border.all(color: palette.border),
                        ),
                        child: SelectableText(
                          reportText ?? '',
                          style: context.text.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: 'Copy to clipboard',
                        icon: Icons.copy_rounded,
                        onPressed: reportText == null
                            ? null
                            : () => _copyToClipboard(reportText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
