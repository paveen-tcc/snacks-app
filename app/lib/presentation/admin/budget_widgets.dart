import 'package:flutter/material.dart';

import '../../core/constants/snack_categories.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/glass.dart';
import '../../core/di/locator.dart';
import '../../core/formatters/rupees.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/microsoft_avatar.dart';
import '../../data/models/budget_models.dart';
import '../../data/repositories/admin_repository.dart';

enum BudgetPeriod { day, week, month }

enum BudgetViewMode { purchases, people }

class BudgetViewModeControl extends StatelessWidget {
  const BudgetViewModeControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final BudgetViewMode value;
  final ValueChanged<BudgetViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<BudgetViewMode>(
        segments: const [
          ButtonSegment(
            value: BudgetViewMode.purchases,
            icon: Icon(Icons.receipt_long_rounded, size: 18),
            label: Text('Purchases', key: Key('budget-view-purchases')),
          ),
          ButtonSegment(
            value: BudgetViewMode.people,
            icon: Icon(Icons.leaderboard_rounded, size: 18),
            label: Text('People Spend', key: Key('budget-view-people')),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
        showSelectedIcon: false,
      ),
    );
  }
}

class BudgetPeriodControl extends StatelessWidget {
  const BudgetPeriodControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final BudgetPeriod value;
  final ValueChanged<BudgetPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<BudgetPeriod>(
        segments: const [
          ButtonSegment(
            value: BudgetPeriod.day,
            label: Text('Day', key: Key('budget-period-day')),
          ),
          ButtonSegment(
            value: BudgetPeriod.week,
            label: Text('Week', key: Key('budget-period-week')),
          ),
          ButtonSegment(
            value: BudgetPeriod.month,
            label: Text('Month', key: Key('budget-period-month')),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
        showSelectedIcon: false,
      ),
    );
  }
}

class BudgetTypeControl extends StatelessWidget {
  const BudgetTypeControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final BudgetTypeFilter value;
  final ValueChanged<BudgetTypeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<BudgetTypeFilter>(
        segments: const [
          ButtonSegment(
            value: BudgetTypeFilter.all,
            label: Text('All', key: Key('budget-filter-all')),
          ),
          ButtonSegment(
            value: BudgetTypeFilter.snacks,
            label: Text('Snacks', key: Key('budget-filter-snacks')),
          ),
          ButtonSegment(
            value: BudgetTypeFilter.drinks,
            label: Text('Drinks', key: Key('budget-filter-drinks')),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
        showSelectedIcon: false,
      ),
    );
  }
}

class BudgetSummaryCards extends StatelessWidget {
  const BudgetSummaryCards({super.key, required this.totals});

  final BudgetTotals totals;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final total = totals.total;
    final snacks = totals.snacks;
    final drinks = totals.drinks;

    final snackRatio = total > 0 ? (snacks / total).clamp(0.0, 1.0) : 0.5;
    final drinkRatio = total > 0 ? (drinks / total).clamp(0.0, 1.0) : 0.5;

    final snackColor = palette.warning;
    final drinkColor = palette.info;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: palette.border),
        boxShadow: context.shadows.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single-line header: Total amount on left, Snacks and Drinks breakdown on right
          Row(
            children: [
              Text(
                formatRupees(total),
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              _BudgetLegendItem(
                color: snackColor,
                label: 'Snacks ${formatRupees(snacks)}',
              ),
              const SizedBox(width: AppSpacing.sm),
              _BudgetLegendItem(
                color: drinkColor,
                label: 'Drinks ${formatRupees(drinks)}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          // Animated horizontal bar chart
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: TweenAnimationBuilder<double>(
                duration: AppMotion.base,
                curve: AppMotion.standard,
                tween: Tween<double>(begin: 0.0, end: total > 0 ? 1.0 : 0.0),
                builder: (context, anim, child) {
                  if (total == 0) {
                    return Container(
                      color: palette.surfaceMuted,
                    );
                  }
                  return Row(
                    children: [
                      if (snacks > 0)
                        Expanded(
                          flex: (snackRatio * 1000 * anim).round().clamp(1, 1000),
                          child: Container(
                            color: snackColor,
                          ),
                        ),
                      if (snacks > 0 && drinks > 0)
                        const SizedBox(width: 2),
                      if (drinks > 0)
                        Expanded(
                          flex: (drinkRatio * 1000 * anim).round().clamp(1, 1000),
                          child: Container(
                            color: drinkColor,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetLegendItem extends StatelessWidget {
  const _BudgetLegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class BudgetDailyTotalRow extends StatelessWidget {
  const BudgetDailyTotalRow({
    super.key,
    required this.day,
    required this.filter,
    required this.maxAmount,
    required this.label,
    required this.onTap,
  });

  final BudgetDay day;
  final BudgetTypeFilter filter;
  final int maxAmount;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final amount = filter.amountFrom(day.totals);
    final fraction = maxAmount <= 0
        ? 0.0
        : (amount / maxAmount).clamp(0.0, 1.0);
    return InkWell(
      key: Key('budget-day-${day.date}'),
      onTap: onTap,
      borderRadius: AppRadii.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 86,
              child: Text(label, style: context.text.labelLarge),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadii.rPill,
                child: Container(
                  height: 9,
                  color: palette.surfaceMuted,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: fraction,
                    child: ColoredBox(color: palette.brand),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 72,
              child: Text(
                formatRupees(amount),
                textAlign: TextAlign.end,
                style: context.text.labelLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetItemTotalRow extends StatelessWidget {
  const BudgetItemTotalRow({super.key, required this.item});

  final BudgetItemTotal item;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDrink = item.itemType == BudgetItemType.drink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isDrink ? palette.info : palette.warning).withValues(
                alpha: 0.12,
              ),
              borderRadius: AppRadii.rSm,
            ),
            child: Icon(
              isDrink ? Icons.local_cafe_rounded : Icons.restaurant_rounded,
              size: 18,
              color: isDrink ? palette.info : palette.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: context.text.titleSmall),
                Text(
                  '${item.quantity} purchased',
                  style: context.text.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatRupees(item.totalRupees),
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class UserSpendingStatsCard extends StatelessWidget {
  const UserSpendingStatsCard({
    super.key,
    required this.userSpendings,
    required this.filter,
  });

  final List<UserSpending> userSpendings;
  final BudgetTypeFilter filter;

  @override
  Widget build(BuildContext context) {
    final activeUsers = userSpendings
        .where((u) => u.amountForFilter(filter) > 0)
        .toList();
    final totalSpend = activeUsers.fold<int>(
      0,
      (sum, u) => sum + u.amountForFilter(filter),
    );
    final count = activeUsers.length;
    final avgSpend = count > 0 ? (totalSpend / count).round() : 0;
    final topSpender = activeUsers.isNotEmpty ? activeUsers.first : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        if (!compact) {
          return Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Active spenders',
                  value: '$count ${count == 1 ? 'person' : 'people'}',
                  icon: Icons.people_alt_rounded,
                  accent: context.palette.brand,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _KpiCard(
                  label: 'Average spend',
                  value: formatRupees(avgSpend),
                  icon: Icons.analytics_rounded,
                  accent: context.palette.info,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _KpiCard(
                  label: 'Top spender',
                  value: topSpender != null
                      ? '${topSpender.username} (${formatRupees(topSpender.amountForFilter(filter))})'
                      : '—',
                  icon: Icons.military_tech_rounded,
                  accent: context.palette.warning,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: 'Active spenders',
                    value: '$count ${count == 1 ? 'person' : 'people'}',
                    icon: Icons.people_alt_rounded,
                    accent: context.palette.brand,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _KpiCard(
                    label: 'Average spend',
                    value: formatRupees(avgSpend),
                    icon: Icons.analytics_rounded,
                    accent: context.palette.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _KpiCard(
              label: 'Top spender',
              value: topSpender != null
                  ? '${topSpender.username} (${formatRupees(topSpender.amountForFilter(filter))})'
                  : '—',
              icon: Icons.military_tech_rounded,
              accent: context.palette.warning,
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadii.rSm,
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: context.text.labelSmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class UserSpendingRow extends StatelessWidget {
  const UserSpendingRow({
    super.key,
    required this.user,
    required this.rank,
    required this.filter,
    required this.maxAmount,
    required this.onTap,
  });

  final UserSpending user;
  final int rank;
  final BudgetTypeFilter filter;
  final int maxAmount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final totalAmount = user.amountForFilter(filter);
    final snackAmount = user.snackSpendRupees;
    final drinkAmount = user.drinkSpendRupees;
    final totalFraction = maxAmount <= 0
        ? 0.0
        : (totalAmount / maxAmount).clamp(0.0, 1.0);

    final snackRatio = totalAmount > 0 ? (snackAmount / totalAmount) : 0.0;
    final drinkRatio = totalAmount > 0 ? (drinkAmount / totalAmount) : 0.0;

    final rankColor = switch (rank) {
      1 => const Color(0xFFEAB308),
      2 => const Color(0xFF94A3B8),
      3 => const Color(0xFFD97706),
      _ => palette.textTertiary,
    };

    final isTop3 = rank <= 3;

    return InkWell(
      key: Key('user-spending-${user.userId}'),
      onTap: onTap,
      borderRadius: AppRadii.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isTop3
                        ? rankColor.withValues(alpha: 0.18)
                        : palette.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$rank',
                    style: context.text.labelSmall?.copyWith(
                      color: isTop3 ? rankColor : palette.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                MicrosoftAvatar(
                  displayName: user.username,
                  userPrincipalName: user.email,
                  radius: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${user.totalOrdersCount} ${user.totalOrdersCount == 1 ? 'item' : 'items'} ordered',
                        style: context.text.bodySmall?.copyWith(
                          color: palette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formatRupees(totalAmount),
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: palette.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadii.rPill,
              child: Container(
                height: 8,
                color: palette.surfaceMuted,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: totalFraction,
                  child: filter == BudgetTypeFilter.all
                      ? Row(
                          children: [
                            if (snackRatio > 0)
                              Flexible(
                                flex: (snackRatio * 1000).round(),
                                child: Container(color: palette.warning),
                              ),
                            if (drinkRatio > 0)
                              Flexible(
                                flex: (drinkRatio * 1000).round(),
                                child: Container(color: palette.info),
                              ),
                          ],
                        )
                      : Container(
                          color: filter == BudgetTypeFilter.drinks
                              ? palette.info
                              : palette.warning,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showUserSpendingSheet({
  required BuildContext context,
  required UserSpending user,
  required BudgetTypeFilter filter,
  String? periodLabel,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => _UserSpendingDetailSheet(
      user: user,
      filter: filter,
      periodLabel: periodLabel,
    ),
  );
}

class _UserSpendingDetailSheet extends StatelessWidget {
  const _UserSpendingDetailSheet({
    required this.user,
    required this.filter,
    this.periodLabel,
  });

  final UserSpending user;
  final BudgetTypeFilter filter;
  final String? periodLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final items = user.itemsForFilter(filter);
    final totalAmount = user.amountForFilter(filter);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MicrosoftAvatar(
                displayName: user.username,
                userPrincipalName: user.email,
                radius: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: context.text.headlineSmall),
                    if (user.email.isNotEmpty)
                      Text(
                        user.email,
                        style: context.text.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (periodLabel != null)
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
                  child: Text(
                    periodLabel!,
                    style: context.text.labelSmall?.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadii.rLg,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Spend',
                        style: context.text.labelSmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupees(totalAmount),
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.brand,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: palette.divider),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Snacks',
                        style: context.text.labelSmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupees(user.snackSpendRupees),
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: palette.divider),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Drinks',
                        style: context.text.labelSmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupees(user.drinkSpendRupees),
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (user.dailySpend.length > 1) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Daily Spend Timeline', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadii.rMd,
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  for (final daily in user.dailySpend) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(
                              daily.date,
                              style: context.text.bodySmall?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${daily.itemCount} ${daily.itemCount == 1 ? 'item' : 'items'}',
                              style: context.text.bodySmall,
                            ),
                          ),
                          Text(
                            formatRupees(daily.totalRupees),
                            style: context.text.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Itemized Breakdown', style: context.text.titleSmall),
              Text(
                '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                style: context.text.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'No items in this filter',
                  style: context.text.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
            )
          else
            for (final item in items) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: AppRadii.rMd,
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (item.itemType == BudgetItemType.drink
                                  ? palette.info
                                  : palette.warning)
                              .withValues(alpha: 0.12),
                          borderRadius: AppRadii.rSm,
                        ),
                        child: Icon(
                          item.itemType == BudgetItemType.drink
                              ? Icons.local_cafe_rounded
                              : Icons.restaurant_rounded,
                          size: 18,
                          color: item.itemType == BudgetItemType.drink
                              ? palette.info
                              : palette.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: context.text.titleSmall,
                            ),
                            Text(
                              '${item.quantity} × ${formatRupees(item.unitPriceRupees)}',
                              style: context.text.bodySmall?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatRupees(item.totalRupees),
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class BudgetPurchaseLineCard extends StatelessWidget {
  const BudgetPurchaseLineCard({
    super.key,
    required this.line,
    required this.onEdit,
    required this.onRemove,
    this.isBusy = false,
  });

  final BudgetLine line;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDrink = line.itemType == BudgetItemType.drink;
    final accent = isDrink ? palette.info : palette.warning;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: palette.border),
        boxShadow: context.shadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: AppRadii.rMd,
            ),
            child: Icon(
              isDrink ? Icons.local_cafe_rounded : Icons.restaurant_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(line.name, style: context.text.titleMedium),
                    ),
                    if (line.isManual)
                      _LineBadge(label: 'Custom', color: palette.info)
                    else if (line.isEdited)
                      _LineBadge(label: 'Edited', color: palette.warning),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${line.quantity} × ${formatRupees(line.unitPriceRupees)}',
                  style: context.text.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  formatRupees(line.lineTotalRupees),
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Column(
              children: [
                IconButton(
                  tooltip: 'Edit ${line.name}',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Remove ${line.name}',
                  onPressed: onRemove,
                  color: palette.danger,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LineBadge extends StatelessWidget {
  const _LineBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class BudgetSearchField extends StatefulWidget {
  const BudgetSearchField({
    super.key,
    required this.query,
    required this.onChanged,
  });

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<BudgetSearchField> createState() => _BudgetSearchFieldState();
}

class _BudgetSearchFieldState extends State<BudgetSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void didUpdateWidget(covariant BudgetSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 44,
      child: TextField(
        key: const Key('budget-search'),
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        style: context.text.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search purchase lines',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: palette.textTertiary,
            size: 20,
          ),
          suffixIcon: widget.query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                ),
          isDense: true,
        ),
      ),
    );
  }
}

Future<void> showBudgetItemSheet({
  required BuildContext context,
  required Future<void> Function(Map<String, dynamic> data) onSave,
  BudgetLine? line,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => _BudgetItemForm(line: line, onSave: onSave),
  );
}

class _BudgetItemForm extends StatefulWidget {
  const _BudgetItemForm({required this.line, required this.onSave});

  final BudgetLine? line;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_BudgetItemForm> createState() => _BudgetItemFormState();
}

class _BudgetItemFormState extends State<_BudgetItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late BudgetItemType _type;
  bool _saving = false;
  String? _saveError;
  List<Map<String, dynamic>>? _catalog;

  @override
  void initState() {
    super.initState();
    final line = widget.line;
    _nameController = TextEditingController(text: line?.name ?? '');
    _nameFocusNode = FocusNode();
    _quantityController = TextEditingController(
      text: line?.quantity.toString() ?? '1',
    );
    _priceController = TextEditingController(
      text: line?.unitPriceRupees.toString() ?? '',
    );
    _type = line?.itemType ?? BudgetItemType.snack;
    _quantityController.addListener(_recomputeTotal);
    _priceController.addListener(_recomputeTotal);
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final snacks = await locator<AdminRepository>().getAllSnacks();
      if (!mounted) return;
      setState(() {
        _catalog = snacks
            .where((snack) => (snack['isActive'] as bool?) ?? true)
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _catalog = const []);
    }
  }

  void _recomputeTotal() => setState(() {});

  int? get _liveLineTotal {
    final quantity = int.tryParse(_quantityController.text.trim());
    final price = parseWholeRupees(_priceController.text);
    if (quantity == null || quantity < 1 || price == null) return null;
    return quantity * price;
  }

  Iterable<Map<String, dynamic>> _catalogOptions(TextEditingValue value) {
    final catalog = _catalog;
    final query = value.text.trim().toLowerCase();
    if (catalog == null || catalog.isEmpty || query.isEmpty) return const [];
    return catalog.where(
      (item) => (item['name'] as String? ?? '').toLowerCase().contains(query),
    );
  }

  void _onCatalogItemSelected(Map<String, dynamic> item) {
    final price = (item['priceRupees'] as num?)?.toInt();
    final category = item['category'] as String?;
    setState(() {
      if (price != null) _priceController.text = price.toString();
      _type = displaySnackCategory(category).toLowerCase() == 'drinks'
          ? BudgetItemType.drink
          : BudgetItemType.snack;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _quantityController.removeListener(_recomputeTotal);
    _priceController.removeListener(_recomputeTotal);
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final price = parseWholeRupees(_priceController.text)!;
    final quantity = int.parse(_quantityController.text.trim());
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave({
        'name': _nameController.text.trim(),
        'itemType': _type.jsonValue,
        'quantity': quantity,
        'unitPriceRupees': price,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final editing = widget.line != null;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editing ? 'Edit purchase item' : 'Add custom item',
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              editing
                  ? 'Correct what was actually purchased.'
                  : 'Add a one-off purchase without changing the catalog.',
              style: context.text.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            RawAutocomplete<Map<String, dynamic>>(
              textEditingController: _nameController,
              focusNode: _nameFocusNode,
              optionsBuilder: _catalogOptions,
              displayStringForOption: (item) => item['name'] as String? ?? '',
              onSelected: _onCatalogItemSelected,
              fieldViewBuilder: (context, controller, focusNode, _) =>
                  TextFormField(
                    key: const Key('budget-item-name'),
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Item name',
                      hintText: 'Search the catalog or type a custom name',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter an item name'
                        : null,
                  ),
              optionsViewBuilder: (context, onSelected, options) {
                final list = options.toList();
                final width =
                    MediaQuery.sizeOf(context).width - (AppSpacing.xxl * 2);
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: AppRadii.rMd,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: width,
                        maxHeight: 220,
                      ),
                      child: ListView.builder(
                        key: const Key('budget-item-name-options'),
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final price =
                              (item['priceRupees'] as num?)?.toInt() ?? 0;
                          return ListTile(
                            dense: true,
                            title: Text(item['name'] as String? ?? ''),
                            trailing: Text(formatRupees(price)),
                            onTap: () => onSelected(item),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<BudgetItemType>(
              key: const Key('budget-item-type'),
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: BudgetItemType.snack,
                  child: Text('Snack'),
                ),
                DropdownMenuItem(
                  value: BudgetItemType.drink,
                  child: Text('Drink'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('budget-item-quantity'),
                    controller: _quantityController,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: (value) {
                      final quantity = int.tryParse(value?.trim() ?? '');
                      return quantity == null || quantity < 1
                          ? 'Enter 1 or more'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    key: const Key('budget-item-price'),
                    controller: _priceController,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Unit price (₹)',
                    ),
                    validator: (value) => parseWholeRupees(value ?? '') == null
                        ? 'Enter a whole-rupee price (0 or more)'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _liveLineTotal != null
                  ? 'Line total: ${formatRupees(_liveLineTotal!)}'
                  : 'Line total: —',
              style: context.text.bodyMedium?.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _saveError!,
                style: context.text.bodySmall?.copyWith(color: palette.danger),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              key: const Key('budget-save-item'),
              label: 'Save item',
              loading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
