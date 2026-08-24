import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/snack_categories.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/food_card.dart';
import 'bloc/home_bloc.dart';
import 'home_helpers.dart';
import 'widgets/dispenser/drink_dispenser_models.dart';
import 'widgets/dispenser/drink_dispenser_stage.dart';
import 'widgets/drinks_blue_header.dart';
import 'widgets/shutdown_view.dart';

/// Drink tab — 3D Interactive Drink Dispenser with Royal Blue Top Header,
/// with toggle support to switch to a simplified Grid View (off/3D by default).
class DrinkTab extends StatefulWidget {
  const DrinkTab({super.key, this.isActive = true});

  final bool isActive;

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

        final showDispenser =
            !_isGridView && query.isEmpty && allDrinks.isNotEmpty;

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
                onFormatChanged: (format) =>
                    setState(() => _selectedFormat = format),
                topPadding: topPadding,
                isGridView: _isGridView,
                onGridViewChanged: (isGrid) =>
                    setState(() => _isGridView = isGrid),
              ),

              // Dispenser / Simplified Grid View
              Expanded(
                child: RefreshIndicator.adaptive(
                  onRefresh: () async {
                    await refreshHomeAndWait(bloc);
                  },
                  child: showDispenser
                      ? DrinkDispenserStage(
                          allDrinks: allDrinks,
                          selectedSnackIds: state.selectedSnackIds,
                          sugarFreePrefs: state.sugarFreePrefs,
                          hasBottomCart: hasBottomCart,
                          isActive: widget.isActive,
                          selectedFormat: _selectedFormat,
                          onFormatChanged: (format) =>
                              setState(() => _selectedFormat = format),
                          showTopTabs: false,
                          disabled: isClosed,
                          onIncrement: isClosed
                              ? (_) {}
                              : (drink) => bloc.add(IncrementSnack(drink.id)),
                          onDecrement: isClosed
                              ? (_) {}
                              : (drink) => bloc.add(DecrementSnack(drink.id)),
                          onToggleSugarFree: isClosed
                              ? (_) {}
                              : (drink) => bloc.add(ToggleSugarFree(drink.id)),
                        )
                      : CustomScrollView(
                          key: const PageStorageKey('drink_tab_scroll'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            if (state.snacks.isEmpty)
                              SliverPadding(
                                padding: EdgeInsets.only(
                                  bottom: bottomClearance,
                                ),
                                sliver: const SliverToBoxAdapter(
                                  child: _EmptyDrinks(query: ''),
                                ),
                              )
                            else if (displayedDrinks.isEmpty)
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  AppSpacing.page,
                                  AppSpacing.sm,
                                  AppSpacing.page,
                                  bottomClearance,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: _EmptyDrinks(query: query),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  AppSpacing.page,
                                  AppSpacing.sm,
                                  AppSpacing.page,
                                  bottomClearance,
                                ),
                                sliver: SliverLayoutBuilder(
                                  builder: (context, constraints) {
                                    final textScale = MediaQuery.textScalerOf(
                                      context,
                                    ).scale(1).clamp(1.0, 2.0);
                                    final columns =
                                        (constraints.crossAxisExtent / 105)
                                            .floor()
                                            .clamp(3, 8);
                                    final cardWidth =
                                        (constraints.crossAxisExtent -
                                            (columns - 1) * 10) /
                                        columns;
                                    return SliverGrid(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columns,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 12,
                                            mainAxisExtent:
                                                cardWidth +
                                                86 +
                                                ((textScale - 1) * 34),
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
                                          servingSize:
                                              (d.servingSize != null &&
                                                  d.servingSize!
                                                          .toLowerCase() !=
                                                      '1' &&
                                                  d.servingSize!
                                                          .toLowerCase() !=
                                                      '1 serving')
                                              ? d.servingSize
                                              : null,
                                          selected: count > 0,
                                          count: count,
                                          disabled: isClosed,
                                          onTap: isClosed
                                              ? null
                                              : () => bloc.add(
                                                  IncrementSnack(d.id),
                                                ),
                                          onIncrement: isClosed
                                              ? null
                                              : () => bloc.add(
                                                  IncrementSnack(d.id),
                                                ),
                                          onDecrement: isClosed
                                              ? null
                                              : () => bloc.add(
                                                  DecrementSnack(d.id),
                                                ),
                                        );
                                      }, childCount: displayedDrinks.length),
                                    );
                                  },
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
