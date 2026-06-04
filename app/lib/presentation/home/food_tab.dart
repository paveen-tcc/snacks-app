import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/snack_categories.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/category_scroller.dart';
import '../../core/widgets/food_card.dart';
import '../../core/widgets/illustrations.dart';
import 'bloc/home_bloc.dart';
import 'home_helpers.dart';
import 'widgets/search_veg_row.dart';

/// Food tab — always-visible search + veg row, status banner, category chips,
/// and the snack list. Drinks now live in their own tab.
class FoodTab extends StatefulWidget {
  const FoodTab({super.key});

  @override
  State<FoodTab> createState() => _FoodTabState();
}

class _FoodTabState extends State<FoodTab> {
  String _category = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded) return const SizedBox.shrink();
        final bloc = context.read<HomeBloc>();

        if (state.isShutdown) return _Shutdown(state: state);

        final isVegMode = state.filter == 'Veg';
        final closed = isOrderingClosed(state);

        // Food categories only (no "Drinks").
        final categories = [
          'All',
          ...buildCategoryOptions(
            state.snacks,
          ).where((c) => c != 'All' && c != 'Drinks'),
        ];
        final category = categories.contains(_category) ? _category : 'All';

        final query = _query.trim().toLowerCase();
        final snacks = state.snacks.where((s) {
          if (isVegMode && s.isVeg != true) return false;
          if (category != 'All' &&
              displaySnackCategory(s.category) != category) {
            return false;
          }
          if (query.isNotEmpty &&
              !s.name.toLowerCase().contains(query) &&
              !(s.description ?? '').toLowerCase().contains(query)) {
            return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            SearchVegRow(
              query: _query,
              onQueryChanged: (q) => setState(() => _query = q),
              showVeg: true,
              vegOn: isVegMode,
              onVegChanged: (v) => bloc.add(ChangeFilter(v ? 'Veg' : 'All')),
              hint: 'Search snacks',
            ),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: () async {
                  bloc.add(RefreshHome());
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.sm,
                        AppSpacing.page,
                        0,
                      ),
                      sliver: SliverList.list(
                        children: [
                          _StatusBanner(state: state),
                          const SizedBox(height: AppSpacing.lg),
                          if (!closed)
                            CategoryScroller(
                              items: _categoryItems(categories),
                              selectedKey: category,
                              padding: EdgeInsets.zero,
                              onSelected: (k) => setState(() => _category = k),
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          if (closed) _CutoffClosedCard(state: state),
                          if (snacks.isEmpty && !closed)
                            _EmptyResults(query: query),
                        ],
                      ),
                    ),
                    if (snacks.isNotEmpty && !closed)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          0,
                          AppSpacing.page,
                          AppSpacing.x5 + AppSpacing.x5 + AppSpacing.lg,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: AppSpacing.md,
                                mainAxisSpacing: AppSpacing.xl,
                                mainAxisExtent: 224,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final s = snacks[index];
                            return SnackCard(
                              name: s.name,
                              isVeg: s.isVeg,
                              description: s.description,
                              emoji: s.emoji,
                              servingSize: s.servingSize ?? '1 Unit',
                              selected: state.selectedSnackIds.contains(s.id),
                              onTap: () => bloc.add(ToggleSnack(s.id)),
                            );
                          }, childCount: snacks.length),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<CategoryItem> _categoryItems(List<String> categories) {
    return [
      for (final c in categories)
        CategoryItem(
          key: c,
          label: c,
          emoji: c == 'All' ? '🍽️' : snackCategoryIcon(c),
        ),
    ];
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final closed = isOrderingClosed(state);
    final closeTime = formatOrderWindowCloseTime(state);
    final windowLabel = formatTimeRange(
      state.advanceWindowStart,
      state.advanceWindowEnd,
    );
    final isAdvance = state.advanceOrderMode && !closed;

    final tone = isAdvance
        ? StatusTone.warning
        : closed
        ? StatusTone.neutral
        : StatusTone.info;
    final icon = isAdvance
        ? Icons.event_available_rounded
        : closed
        ? Icons.timer_off_rounded
        : Icons.schedule_rounded;
    final title = isAdvance
        ? 'Advance Order Mode'
        : state.advanceOrderMode && closed
        ? 'Ordering is closed for today.'
        : closed
        ? 'Order window closed at $closeTime'
        : 'Order your snacks before the window closes at $closeTime';
    final subtitle = isAdvance
        ? 'You are ordering for tomorrow, ${formatAdvanceOrderDate()}. Window: $windowLabel.'
        : state.advanceOrderMode && closed
        ? 'Advance order window: $windowLabel.'
        : closed
        ? 'Come back tomorrow for the next snack window'
        : 'You can edit your order until $closeTime';

    return StatusBanner(
      tone: tone,
      icon: icon,
      title: title,
      subtitle: subtitle,
    );
  }
}

class _CutoffClosedCard extends StatelessWidget {
  const _CutoffClosedCard({required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final namesById = {for (final s in state.snacks) s.id: s.name};
    final ordered = state.todaysOrders
        .map((o) => namesById[o.snackId])
        .whereType<String>()
        .toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.info.withValues(alpha: 0.14),
                  borderRadius: AppRadii.rMd,
                ),
                child: Icon(Icons.timer_off_rounded, color: palette.info),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Snack ordering is closed for today',
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      state.advanceOrderMode
                          ? 'Advance order window: ${formatTimeRange(state.advanceWindowStart, state.advanceWindowEnd)}.'
                          : 'The order window closed at ${formatOrderWindowCloseTime(state)}.',
                      style: context.text.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ordered.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadii.rMd,
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your selection', style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    ordered.join(', '),
                    style: context.text.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x4),
      child: Center(
        child: Column(
          children: [
            const EmptyStateIllustration(emoji: '🔍', size: 120),
            const SizedBox(height: AppSpacing.lg),
            Text(
              query.isEmpty ? 'No snacks here' : 'No snacks match "$query"',
              style: context.text.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Shutdown extends StatelessWidget {
  const _Shutdown({required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ShutdownIllustration(width: 220),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              state.shutdownType == 'holiday'
                  ? 'Happy Holiday!'
                  : 'No Orders Today',
              style: context.text.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.shutdownReason ?? 'The kitchen is taking a break today',
              style: context.text.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            StatusBanner(
              tone: StatusTone.info,
              icon: state.shutdownType == 'holiday'
                  ? Icons.celebration_rounded
                  : Icons.info_outline_rounded,
              title: 'Orders will resume on the next working day',
            ),
          ],
        ),
      ),
    );
  }
}
