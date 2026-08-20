import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/food_assets.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/widgets/optimized_image.dart';
import '../../core/design/glass.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/food_card.dart' show VegBadge;
import '../../data/local/app_database.dart';
import 'bloc/home_bloc.dart';
import 'home_helpers.dart';

/// Sticky "View Cart" pill, shown above the bottom nav on the Food & Drink tabs.
/// - Unconfirmed state: Pure white card with blue count bubble and dark text.
/// - Confirmed state: Royal Blue gradient card (NOT green).
/// - Animate in: Starts as a circle from bottom and expands horizontally to full rounded pill!
class CartBar extends StatefulWidget {
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
  State<CartBar> createState() => _CartBarState();
}

class _CartBarState extends State<CartBar> with SingleTickerProviderStateMixin {
  late final AnimationController _morphController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );

    // 1. Circle slides up from bottom
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _morphController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    // 2. Circle expands horizontally into pill
    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _morphController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Text content fades in
    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _morphController,
        curve: const Interval(0.60, 1.0, curve: Curves.easeIn),
      ),
    );

    _morphController.forward();
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final orderPlaced = widget.orderPlaced;
    final hasChanges = widget.hasChanges;
    final itemCount = widget.itemCount;

    final title = orderPlaced
        ? 'Order placed'
        : hasChanges
        ? 'Review changes'
        : 'View Cart';
    final subtitle = orderPlaced
        ? 'Tap to edit your order until ${widget.editUntilLabel ?? 'the window closes'}'
        : hasChanges
        ? 'Confirm to update order'
        : itemCount == 1
        ? '1 item selected'
        : '$itemCount items selected';

    return AnimatedBuilder(
      animation: _morphController,
      builder: (context, child) {
        final slideVal = _slideAnimation.value;
        final expandVal = _expandAnimation.value;
        final fadeVal = _contentFadeAnimation.value;

        return Transform.translate(
          offset: Offset(0, slideVal * 60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.center,
              child: PressableScale(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 56,
                  width: expandVal < 0.99
                      ? (56.0 +
                            (MediaQuery.of(context).size.width - 56.0 - 32.0) *
                                expandVal)
                      : double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: expandVal < 0.5 ? 8 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: orderPlaced
                        ? null
                        : (palette.isDark ? palette.surface : Colors.white),
                    gradient: orderPlaced
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: palette.headerGradient,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: orderPlaced
                          ? Colors.white.withValues(alpha: 0.35)
                          : (palette.isDark
                              ? palette.border
                              : const Color(0xFFE2E8F0)),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.brand.withValues(
                          alpha: orderPlaced ? 0.35 : 0.12,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Left Count Bubble
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: orderPlaced
                                ? null
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: palette.headerGradient,
                                  ),
                            color: orderPlaced
                                ? Colors.white.withValues(alpha: 0.22)
                                : null,
                            boxShadow: orderPlaced
                                ? null
                                : [
                                    BoxShadow(
                                      color: palette.brand.withValues(
                                        alpha: 0.30,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$itemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      // Text and chevron (faded in as width expands)
                      if (expandVal > 0.3)
                        Positioned.fill(
                          left: 52,
                          child: Opacity(
                            opacity: fadeVal.clamp(0.0, 1.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: orderPlaced
                                              ? Colors.white
                                              : palette.textPrimary,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: orderPlaced
                                              ? Colors.white.withValues(
                                                  alpha: 0.85,
                                                )
                                              : palette.textSecondary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: orderPlaced
                                      ? Colors.white
                                      : palette.brand,
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
                      IconButton.filledTonal(
                        tooltip: 'Close cart',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
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
                              isSugarFree:
                                  state.sugarFreePrefs[snack.id] ?? false,
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
                      HapticFeedback.heavyImpact();
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
              Builder(
                builder: (context) {
                  final localAsset = resolveLocalFoodAsset(snack.name);
                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: palette.isDark ? palette.surface : Colors.white,
                      gradient: RadialGradient(
                        center: const Alignment(0, 0.05),
                        radius: 0.85,
                        colors: palette.cardGlowGradient,
                        stops: palette.isDark
                            ? const [0.0, 0.55, 1.0]
                            : const [0.0, 0.55, 1.0],
                      ),
                      borderRadius: AppRadii.rMd,
                      border: Border.all(
                        color: palette.isDark
                            ? palette.border
                            : const Color(0xFFE5ECF6),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: localAsset != null
                        ? Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              localAsset,
                              fit: BoxFit.contain,
                              cacheWidth: 160,
                              errorBuilder: (c, e, s) => Icon(
                                Icons.fastfood_rounded,
                                size: 28,
                                color: palette.textSecondary,
                              ),
                            ),
                          )
                        : snack.emoji != null &&
                                (snack.emoji!.startsWith('http://') ||
                                    snack.emoji!.startsWith('https://'))
                            ? OptimizedImage(
                                imageUrl: snack.emoji!,
                                width: 56,
                                height: 56,
                                memCacheWidth: 120,
                                memCacheHeight: 120,
                                borderRadius:
                                    AppRadii.rMd -
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
                  );
                },
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
                                  color: snack.isVeg
                                      ? palette.veg
                                      : palette.nonVeg,
                                ),
                              ),
                            ],
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
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
                          PressableScale(
                            scale: 0.92,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
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
                    PressableScale(
                      scale: 0.85,
                      onTap: () => homeBloc.add(DecrementSnack(snack.id)),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          quantity == 1
                              ? Icons.delete_outline_rounded
                              : Icons.remove_circle_outline_rounded,
                          color: quantity == 1
                              ? palette.danger
                              : palette.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        '$quantity',
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    PressableScale(
                      scale: 0.85,
                      onTap: () => homeBloc.add(IncrementSnack(snack.id)),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.add_circle_outline_rounded,
                          color: palette.brand,
                          size: 24,
                        ),
                      ),
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
