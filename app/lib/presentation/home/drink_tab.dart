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
import 'widgets/dispenser/drink_dispenser_models.dart';
import 'widgets/dispenser/drink_dispenser_stage.dart';
import 'widgets/drinks_blue_header.dart';

/// Drink tab — 3D Interactive Drink Dispenser with Royal Blue Top Header,
/// with toggle support to switch to a simplified Grid View (off/3D by default).
class DrinkTab extends StatefulWidget {
  const DrinkTab({super.key});

  @override
  State<DrinkTab> createState() => _DrinkTabState();
}

class _DrinkTabState extends State<DrinkTab> {
  String _query = '';
  DrinkFormat _selectedFormat = DrinkFormat.coldJuice;
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded) return const SizedBox.shrink();
        final bloc = context.read<HomeBloc>();
        if (isOrderingClosed(state)) return ClosedOrderWindowView(state: state);

        final query = _query.trim().toLowerCase();

        final allDrinks = state.snacks.where((d) {
          return displaySnackCategory(d.category).toLowerCase() == 'drinks';
        }).toList();

        final filteredDrinks = allDrinks.where((d) {
          if (query.isNotEmpty && !d.name.toLowerCase().contains(query)) {
            return false;
          }
          return true;
        }).toList();

        // In Grid mode without a query, filter drinks by the selected format tab
        final displayedDrinks = query.isNotEmpty
            ? filteredDrinks
            : allDrinks.where((d) {
                return DrinkPresentation.fromSnack(d).format == _selectedFormat;
              }).toList();

        final showDispenser = !_isGridView && query.isEmpty && allDrinks.isNotEmpty;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              // Top Royal Blue Header with Search Bar, Format Tabs, and 3D/Grid View Toggle
              DrinksBlueHeader(
                query: _query,
                onQueryChanged: (q) => setState(() => _query = q),
                selectedFormat: _selectedFormat,
                onFormatChanged: (format) => setState(() => _selectedFormat = format),
                topPadding: topPadding,
                isGridView: _isGridView,
                onGridViewChanged: (isGrid) => setState(() => _isGridView = isGrid),
              ),

              // Dispenser / Simplified Grid View
              Expanded(
                child: RefreshIndicator.adaptive(
                  onRefresh: () async {
                    bloc.add(RefreshHome());
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  child: showDispenser
                      ? DrinkDispenserStage(
                          allDrinks: allDrinks,
                          selectedSnackIds: state.selectedSnackIds,
                          selectedFormat: _selectedFormat,
                          onFormatChanged: (format) =>
                              setState(() => _selectedFormat = format),
                          showTopTabs: false,
                          onIncrement: (drink) =>
                              bloc.add(IncrementSnack(drink.id)),
                          onDecrement: (drink) =>
                              bloc.add(DecrementSnack(drink.id)),
                        )
                      : CustomScrollView(
                          key: const PageStorageKey('drink_tab_scroll'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            if (state.snacks.isEmpty)
                              const SliverToBoxAdapter(
                                child: Center(child: FoodLoader(size: 28)),
                              )
                            else if (displayedDrinks.isEmpty)
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
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.page,
                                  AppSpacing.sm,
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
                                    final d = displayedDrinks[index];
                                    final count = state.selectedSnackIds
                                        .where((id) => id == d.id)
                                        .length;
                                    return DrinkCard(
                                      name: d.name,
                                      emoji: d.emoji,
                                      servingSize: (d.servingSize != null &&
                                              d.servingSize!.toLowerCase() !=
                                                  '1' &&
                                              d.servingSize!.toLowerCase() !=
                                                  '1 serving')
                                          ? d.servingSize
                                          : null,
                                      selected: count > 0,
                                      count: count,
                                      onTap: () =>
                                          bloc.add(IncrementSnack(d.id)),
                                      onIncrement: () =>
                                          bloc.add(IncrementSnack(d.id)),
                                      onDecrement: () =>
                                          bloc.add(DecrementSnack(d.id)),
                                    );
                                  }, childCount: displayedDrinks.length),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_drink_outlined,
            size: 48,
            color: context.palette.textTertiary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            query.isEmpty ? 'No drinks available' : 'No drinks match "$query"',
            style: context.text.bodyMedium?.copyWith(
              color: context.palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
