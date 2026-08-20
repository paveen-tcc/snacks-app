import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/snack_categories.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/food_card.dart';
import '../../../data/local/app_database.dart';
import '../bloc/home_bloc.dart';
import '../home_helpers.dart';

/// Displayed in both Food and Drink tabs when the order window has closed for today.
/// Displays a single-line closed message and the user's selected snacks & drinks.
class ClosedOrderWindowView extends StatelessWidget {
  const ClosedOrderWindowView({super.key, required this.state});
  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final snackById = {for (final s in state.snacks) s.id: s};
    final orderedIds = state.selectedSnackIds.isNotEmpty
        ? state.selectedSnackIds
        : state.todaysOrders.map((o) => o.snackId).whereType<String>().toList();

    final selectedItems = orderedIds
        .map((id) => snackById[id])
        .whereType<LocalSnack>()
        .toList();

    final counts = <String, int>{};
    final uniqueItems = <LocalSnack>[];
    for (final item in selectedItems) {
      if (!counts.containsKey(item.id)) uniqueItems.add(item);
      counts[item.id] = (counts[item.id] ?? 0) + 1;
    }

    final closeTime = formatOrderWindowCloseTime(state);

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        context.read<HomeBloc>().add(RefreshHome());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    100,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Single-line closed status banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: AppRadii.rMd,
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_off_rounded,
                              color: palette.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Order window closed today at $closeTime',
                                style: context.text.bodyMedium?.copyWith(
                                  color: palette.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Your Selection Card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your selection',
                              style: context.text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Divider(height: 1, color: palette.divider),
                            const SizedBox(height: AppSpacing.xs),
                            if (uniqueItems.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Center(
                                  child: Text(
                                    'No snacks or drinks ordered for today',
                                    style: context.text.bodySmall?.copyWith(
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            else
                              for (final item in uniqueItems)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    children: [
                                      VegBadge(isVeg: item.isVeg, size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${counts[item.id]} x ',
                                        style: context.text.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: palette.textPrimary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          displaySnackCategory(item.category).toLowerCase() ==
                                                  'drinks'
                                              ? drinkDisplayName(
                                                  item.name,
                                                  state.sugarFreePrefs[item.id] ?? false,
                                                )
                                              : item.name,
                                          style: context.text.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: palette.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
