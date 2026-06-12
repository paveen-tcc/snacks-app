import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/optimized_image.dart';
import '../../core/design/glass.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/food_card.dart' show VegBadge;
import '../../data/local/app_database.dart';
import 'bloc/home_bloc.dart';
import 'home_helpers.dart';

/// Sticky "View Cart" pill (brand-coloured), shown above the bottom nav on the
/// Food & Drink tabs when there are selections.
class CartBar extends StatelessWidget {
  const CartBar({
    super.key,
    required this.itemCount,
    required this.onTap,
    this.orderPlaced = false,
    this.hasChanges = false,
    this.editUntilLabel,
  });

  final int itemCount;
  final VoidCallback onTap;
  final bool orderPlaced;
  final bool hasChanges;
  final String? editUntilLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = orderPlaced ? palette.success : palette.brand;
    final title = orderPlaced
        ? 'Order placed'
        : hasChanges
        ? 'Review changes'
        : 'View Cart';
    final subtitle = orderPlaced
        ? 'Tap to edit your order until ${editUntilLabel ?? 'the window closes'}'
        : hasChanges
        ? 'Confirm to update order'
        : itemCount == 1
        ? '1 item selected'
        : '$itemCount items selected';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: PressableScale(
        onTap: onTap,
        borderRadius: AppRadii.rXl,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadii.rXl,
            boxShadow: context.shadows.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.onBrand.withValues(alpha: 0.18),
                  borderRadius: AppRadii.rMd,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$itemCount',
                  style: context.text.titleMedium?.copyWith(
                    color: palette.onBrand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.text.titleMedium?.copyWith(
                        color: palette.onBrand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: context.text.bodySmall?.copyWith(
                        color: palette.onBrand.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: palette.onBrand,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the cart as a clean modal bottom sheet (snacks + drink + confirm).
void showCartSheet(BuildContext context, HomeBloc homeBloc) {
  showGlassBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: homeBloc,
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is! HomeLoaded) return const SizedBox.shrink();

            final Map<String, int> snackCounts = {};
            for (final id in state.selectedSnackIds) {
              snackCounts[id] = (snackCounts[id] ?? 0) + 1;
            }
            final uniqueSnacks = state.snacks
                .where((s) => snackCounts.containsKey(s.id))
                .toList();
            final itemCount = state.selectedSnackIds.length;
            final orderPlaced = isOrderPlaced(state);
            final hasChanges = hasOrderChanges(state);
            final closeTime = formatOrderWindowCloseTime(state);

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Cart', style: context.text.titleLarge),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              orderPlaced
                                  ? 'Order placed. You can edit it until $closeTime.'
                                  : hasChanges
                                  ? 'Review and confirm your changes.'
                                  : itemCount == 1
                                  ? '1 item selected'
                                  : '$itemCount items selected',
                              style: context.text.bodySmall?.copyWith(
                                color: context.palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final snack in uniqueSnacks) ...[
                            _CartSnackRow(
                              snack: snack,
                              quantity: snackCounts[snack.id] ?? 1,
                              homeBloc: homeBloc,
                              disabled: isOrderingClosed(state),
                              isSugarFree: state.sugarFreePrefs[snack.id] ?? false,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: orderPlaced
                        ? 'Done'
                        : hasSavedOrder(state)
                        ? 'Confirm Changes'
                        : 'Confirm Order',
                    loading: state.isSubmitting,
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      if (!orderPlaced) homeBloc.add(SubmitOrder());
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _CartSnackRow extends StatelessWidget {
  const _CartSnackRow({
    required this.snack,
    required this.quantity,
    required this.homeBloc,
    required this.disabled,
    this.isSugarFree = false,
  });

  final LocalSnack snack;
  final int quantity;
  final HomeBloc homeBloc;
  final bool disabled;
  final bool isSugarFree;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDrink = isDrinkCategory(snack);
    final displayName = isDrink
        ? drinkDisplayName(snack.name, isSugarFree)
        : snack.name;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: AppRadii.rMd,
                  border: Border.all(color: palette.border),
                ),
                alignment: Alignment.center,
                child: snack.emoji != null &&
                        (snack.emoji!.startsWith('http://') ||
                            snack.emoji!.startsWith('https://'))
                    ? OptimizedImage(
                        imageUrl: snack.emoji!,
                        width: 56,
                        height: 56,
                        memCacheWidth: 120,
                        memCacheHeight: 120,
                        borderRadius: AppRadii.rMd -
                            const BorderRadius.all(Radius.circular(1)),
                        fallbackIcon: Icon(
                          Icons.fastfood_rounded,
                          size: 28,
                          color: palette.textSecondary,
                        ),
                      )
                    : Text(
                        snack.emoji ?? '🍽️',
                        style: const TextStyle(fontSize: 28),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!isDrink)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VegBadge(isVeg: snack.isVeg),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                snack.isVeg ? 'Veg' : 'Non-veg',
                                style: context.text.labelSmall?.copyWith(
                                  color:
                                      snack.isVeg ? palette.veg : palette.nonVeg,
                                ),
                              ),
                            ],
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: AppRadii.rPill,
                            border: Border.all(color: palette.border),
                          ),
                          child: Text(
                            snack.servingSize ?? '1 Unit',
                            style: context.text.labelSmall?.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                        if (isDrink)
                          GestureDetector(
                            onTap: disabled
                                ? null
                                : () => homeBloc.add(ToggleSugarFree(snack.id)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSugarFree
                                    ? palette.brand.withValues(alpha: 0.1)
                                    : palette.surface,
                                borderRadius: AppRadii.rPill,
                                border: Border.all(
                                  color: isSugarFree
                                      ? palette.brand
                                      : palette.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSugarFree
                                        ? Icons.water_drop
                                        : Icons.water_drop_outlined,
                                    size: 12,
                                    color: isSugarFree
                                        ? palette.brand
                                        : palette.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sugar Free',
                                    style: context.text.labelSmall?.copyWith(
                                      color: isSugarFree
                                          ? palette.brand
                                          : palette.textSecondary,
                                      fontWeight: isSugarFree
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (disabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'Qty: $quantity',
                    style: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => homeBloc.add(DecrementSnack(snack.id)),
                      icon: Icon(
                        quantity == 1
                            ? Icons.delete_outline_rounded
                            : Icons.remove_circle_outline_rounded,
                        color:
                            quantity == 1 ? palette.danger : palette.textSecondary,
                      ),
                      tooltip:
                          quantity == 1 ? 'Remove item' : 'Decrease quantity',
                    ),
                    Text(
                      '$quantity',
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => homeBloc.add(IncrementSnack(snack.id)),
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: palette.brand,
                      ),
                      tooltip: 'Increase quantity',
                    ),
                  ],
                ),
            ],
          ),

        ],
      ),
    );
  }
}
