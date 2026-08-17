import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/snack_categories.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/food_card.dart';
import '../../core/widgets/illustrations.dart';
import 'bloc/home_bloc.dart';
import 'home_helpers.dart';
import 'widgets/closed_window_view.dart';
import 'widgets/search_veg_row.dart';

/// Drink tab — always-visible search row + the drink list.
class DrinkTab extends StatefulWidget {
  const DrinkTab({super.key});

  @override
  State<DrinkTab> createState() => _DrinkTabState();
}

class _DrinkTabState extends State<DrinkTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded) return const SizedBox.shrink();
        final bloc = context.read<HomeBloc>();
        if (isOrderingClosed(state)) return ClosedOrderWindowView(state: state);

        final query = _query.trim().toLowerCase();

        final drinks = state.snacks.where((d) {
          if (displaySnackCategory(d.category).toLowerCase() != 'drinks') {
            return false;
          }
          if (query.isNotEmpty && !d.name.toLowerCase().contains(query)) {
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
                hint: 'Search drinks',
                onQueryChanged: (q) => setState(() => _query = q),
              ),
              Expanded(
                child: RefreshIndicator.adaptive(
                  onRefresh: () async {
                    bloc.add(RefreshHome());
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  child: CustomScrollView(
                    key: const PageStorageKey('drink_tab_scroll'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      if (state.snacks.isEmpty)
                        const SliverToBoxAdapter(
                          child: Center(child: FoodLoader(size: 28)),
                        )
                      else if (drinks.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.page,
                            AppSpacing.sm,
                            AppSpacing.page,
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _EmptyDrinks(query: query),
                          ),
                        ),
                      if (drinks.isNotEmpty)
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
                                  mainAxisExtent: 178,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final d = drinks[index];
                              final count = state.selectedSnackIds
                                  .where((id) => id == d.id)
                                  .length;
                              return DrinkCard(
                                name: d.name,
                                emoji: d.emoji,
                                servingSize: (d.servingSize != null &&
                                        d.servingSize!.toLowerCase() !=
                                            'drink' &&
                                        d.servingSize!.toLowerCase() !=
                                            'drinks')
                                    ? d.servingSize
                                    : null,
                                selected: count > 0,
                                count: count,
                                onTap: () => bloc.add(IncrementSnack(d.id)),
                                onIncrement: () =>
                                    bloc.add(IncrementSnack(d.id)),
                                onDecrement: () =>
                                    bloc.add(DecrementSnack(d.id)),
                              );
                            }, childCount: drinks.length),
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
}

class _EmptyDrinks extends StatelessWidget {
  const _EmptyDrinks({required this.query});
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
              query.isEmpty ? 'No drinks here' : 'No drinks match "$query"',
              style: context.text.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
