import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/snack_categories.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/food_card.dart';
import '../../core/widgets/illustrations.dart';
import 'bloc/home_bloc.dart';
import 'home_helpers.dart';
import 'widgets/home_blue_header.dart';
import 'widgets/shutdown_view.dart';

/// Food tab — continuous top blue header matching Figma (Search, Veg, Categories,
/// Hero Banner with live timer and 3D team visual), followed by the snacks grid.
class FoodTab extends StatefulWidget {
  const FoodTab({super.key, this.isActive = true});

  final bool isActive;

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

        if (state.isShutdown) return ShutdownView(state: state);
        final isClosed = isOrderingClosed(state);
        final hasBottomCart =
            state.selectedSnackIds.isNotEmpty ||
            state.confirmedSnackIds.isNotEmpty ||
            state.todaysOrders.isNotEmpty;
        final bottomClearance =
            AppSpacing.x5 +
            AppSpacing.x5 +
            AppSpacing.lg +
            MediaQuery.paddingOf(context).bottom +
            (hasBottomCart ? 64 : 0);

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
          if (displaySnackCategory(s.category).toLowerCase() == 'drinks') {
            return false;
          }
          if (isVegMode && s.isVeg != true) return false;
          if (category != 'All' &&
              displaySnackCategory(s.category) != category) {
            return false;
          }
          if (query.isNotEmpty && !s.name.toLowerCase().contains(query)) {
            return false;
          }
          return true;
        }).toList();

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: RefreshIndicator.adaptive(
            onRefresh: () async {
              await refreshHomeAndWait(bloc);
            },
            child: CustomScrollView(
              key: const PageStorageKey('food_tab_scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                // 1. Pinned Sticky Search & Category Header (Morphs to Frosted White Glass on scroll)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HomeStickyHeaderDelegate(
                    query: _query,
                    onQueryChanged: (q) => setState(() => _query = q),
                    isVegMode: isVegMode,
                    onVegChanged: (v) =>
                        bloc.add(ChangeFilter(v ? 'Veg' : 'All')),
                    categories: categories,
                    selectedCategory: category,
                    onCategorySelected: (c) => setState(() => _category = c),
                    topPadding: MediaQuery.of(context).padding.top,
                    textScale: MediaQuery.textScalerOf(
                      context,
                    ).scale(1).clamp(1.0, 2.0),
                  ),
                ),

                // 2. Scrollable Blue Hero Banner (Timer, Grab a Bite, Floating Props, Characters)
                SliverToBoxAdapter(
                  child: HomeHeroBanner(
                    state: state,
                    isActive: widget.isActive,
                  ),
                ),
                if (snacks.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.lg,
                      AppSpacing.page,
                      bottomClearance,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _EmptyResults(query: query),
                    ),
                  ),
                if (snacks.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.md,
                      AppSpacing.page,
                      bottomClearance,
                    ),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final textScale = MediaQuery.textScalerOf(
                          context,
                        ).scale(1).clamp(1.0, 2.0);
                        final columns = (constraints.crossAxisExtent / 105)
                            .floor()
                            .clamp(3, 8);
                        final cardWidth =
                            (constraints.crossAxisExtent - (columns - 1) * 10) /
                            columns;
                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                                mainAxisExtent:
                                    cardWidth + 86 + ((textScale - 1) * 34),
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
                              disabled: isClosed,
                              onTap: isClosed
                                  ? null
                                  : () => bloc.add(IncrementSnack(s.id)),
                              onIncrement: isClosed
                                  ? null
                                  : () => bloc.add(IncrementSnack(s.id)),
                              onDecrement: isClosed
                                  ? null
                                  : () => bloc.add(DecrementSnack(s.id)),
                            );
                          }, childCount: snacks.length),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
