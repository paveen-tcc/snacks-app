import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/snack_categories.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/food_card.dart';
import '../../core/widgets/illustrations.dart';
import '../../core/widgets/optimized_image.dart';
import 'bloc/home_bloc.dart';
import 'home_helpers.dart';
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
        final closed = isOrderingClosed(state);
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

        return Column(
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
                          Text(
                            closed
                                ? 'Drink selection is closed for today.'
                                : state.advanceOrderMode
                                ? 'Choose your drink for tomorrow.'
                                : 'Choose your drink for today.',
                            style: context.text.bodyMedium?.copyWith(
                              color: context.palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (closed)
                            _DrinksClosedCard(state: state)
                          else if (state.snacks.isEmpty)
                            const Center(child: FoodLoader(size: 28))
                          else if (drinks.isEmpty)
                            _EmptyDrinks(query: query),
                        ],
                      ),
                    ),
                    if (drinks.isNotEmpty && !closed)
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
                            final d = drinks[index];
                            return DrinkCard(
                              name: d.name,
                              emoji: d.emoji,
                              servingSize: d.servingSize ?? 'Drink',
                              selected: state.selectedSnackIds.contains(d.id),
                              onTap: () {
                                bloc.add(ToggleSnack(d.id));
                              },
                            );
                          }, childCount: drinks.length),
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
}

class _DrinksClosedCard extends StatelessWidget {
  const _DrinksClosedCard({required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selectedDrinks = state.snacks
        .where((s) =>
            displaySnackCategory(s.category).toLowerCase() == 'drinks' &&
            state.selectedSnackIds.contains(s.id))
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drink selection closed',
            style: context.text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
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
          if (selectedDrinks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final d in selectedDrinks) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadii.rMd,
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    d.emoji != null &&
                            (d.emoji!.startsWith('http://') ||
                                d.emoji!.startsWith('https://'))
                        ? OptimizedImage(
                            imageUrl: d.emoji!,
                            width: 18,
                            height: 18,
                            memCacheWidth: 40,
                            memCacheHeight: 40,
                            borderRadius: BorderRadius.circular(4),
                            fallbackIcon: Icon(
                              Icons.local_cafe_rounded,
                              size: 18,
                              color: palette.textSecondary,
                            ),
                          )
                        : Text(
                            d.emoji ?? '🥤',
                            style: const TextStyle(fontSize: 18),
                          ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Selected drink: ${drinkDisplayName(d.name, state.sugarFreePrefs[d.id] ?? false)}',
                      style: context.text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
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
