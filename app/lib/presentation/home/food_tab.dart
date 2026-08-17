import 'dart:async';

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
import 'widgets/closed_window_view.dart';
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
        if (isOrderingClosed(state)) return ClosedOrderWindowView(state: state);

        final isVegMode = state.filter == 'Veg';

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
          if (displaySnackCategory(s.category).toLowerCase() == 'drinks') return false;
          if (isVegMode && s.isVeg != true) return false;
          if (category != 'All' &&
              displaySnackCategory(s.category) != category) {
            return false;
          }
          if (query.isNotEmpty &&
              !s.name.toLowerCase().contains(query)) {
            return false;
          }
          return true;
        }).toList();

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              SearchVegRow(
                query: _query,
                onQueryChanged: (q) => setState(() => _query = q),
                toggleLabel: 'VEG',
                toggleValue: isVegMode,
                onToggleChanged: (v) => bloc.add(ChangeFilter(v ? 'Veg' : 'All')),
                toggleActiveColor: context.palette.veg,
                hint: 'Search snacks',
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: CategoryScroller(
                  items: _categoryItems(categories),
                  selectedKey: category,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page,
                  ),
                  onSelected: (k) => setState(() => _category = k),
                ),
              ),
              Expanded(
                child: RefreshIndicator.adaptive(
                  onRefresh: () async {
                    bloc.add(RefreshHome());
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  child: CustomScrollView(
                    key: const PageStorageKey('food_tab_scroll'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      if (snacks.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.page,
                            AppSpacing.sm,
                            AppSpacing.page,
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _EmptyResults(query: query),
                          ),
                        ),
                      if (snacks.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.page,
                            AppSpacing.xs,
                            AppSpacing.page,
                            AppSpacing.x5 + AppSpacing.x5 + AppSpacing.lg,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  mainAxisExtent: 198,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final s = snacks[index];
                              final count = state.selectedSnackIds
                                  .where((id) => id == s.id)
                                  .length;
                              return SnackCard(
                                name: s.name,
                                isVeg: s.isVeg,
                                emoji: s.emoji,
                                servingSize: s.servingSize ?? '1 Unit',
                                selected: count > 0,
                                count: count,
                                onTap: () => bloc.add(IncrementSnack(s.id)),
                                onIncrement: () => bloc.add(IncrementSnack(s.id)),
                                onDecrement: () => bloc.add(DecrementSnack(s.id)),
                              );
                            }, childCount: snacks.length),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<CategoryItem> _categoryItems(List<String> categories) {
    return [
      for (final c in categories) ...[
        () {
          final pair = snackCategoryIconPair(c);
          return CategoryItem(
            key: c,
            label: c,
            icon: pair.unselected,
            selectedIcon: pair.selected,
            emoji: c == 'All' ? '🍽️' : snackCategoryIcon(c),
          );
        }(),
      ],
    ];
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
