import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'optimized_image.dart';

import '../design/app_theme.dart';
import '../design/app_colors.dart';
import '../design/app_tokens.dart';

/// The Swiggy/Zomato-style veg/non-veg indicator: a bordered square with a
/// center dot (green = veg, red = non-veg).
class VegBadge extends StatelessWidget {
  const VegBadge({super.key, required this.isVeg, this.size = 14});

  final bool isVeg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? context.palette.veg : context.palette.nonVeg;
    return Semantics(
      label: isVeg ? 'Vegetarian' : 'Non-vegetarian',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Center(
          child: Container(
            width: size * 0.44,
            height: size * 0.44,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

/// Compact product tile for the content layer (snacks & drinks).
class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.name,
    required this.isVeg,
    required this.selected,
    this.count = 0,
    this.emoji,
    this.servingSize,
    this.onTap,
    this.onIncrement,
    this.onDecrement,
    this.fallbackEmoji = '🍽️',
    this.showVegBadge = true,
  });

  final String name;
  final bool isVeg;
  final bool selected;
  final int count;
  final String? emoji;
  final String? servingSize;
  final VoidCallback? onTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final String fallbackEmoji;
  final bool showVegBadge;

  void _handleTap() {
    HapticFeedback.selectionClick();
    if (count == 0) {
      if (onIncrement != null) {
        onIncrement!();
      } else {
        onTap?.call();
      }
    } else {
      onTap?.call();
    }
  }

  Widget _buildContent(String val, AppPalette palette) {
    if (val.startsWith('http://') || val.startsWith('https://')) {
      return OptimizedImage(
        imageUrl: val,
        width: 120,
        height: 120,
        memCacheWidth: 300,
        memCacheHeight: 300,
        borderRadius: AppRadii.rMd - const BorderRadius.all(Radius.circular(1)),
        fallbackIcon: Icon(
          Icons.fastfood_rounded,
          size: 38,
          color: palette.textSecondary,
        ),
      );
    }
    return Text(
      val,
      style: const TextStyle(fontSize: 38),
      maxLines: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveCount = count > 0 ? count : (selected ? 1 : 0);
    final isSelected = effectiveCount > 0;

    // Filter out "drink" / "drinks" from servingSize
    final hasValidServingSize = servingSize != null &&
        servingSize!.trim().isNotEmpty &&
        servingSize!.trim().toLowerCase() != 'drink' &&
        servingSize!.trim().toLowerCase() != 'drinks';

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '$name${showVegBadge ? (isVeg ? ', Veg' : ', Non-veg') : ''}${isSelected ? ', $effectiveCount added' : ''}',
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppMotion.base,
          curve: AppMotion.standard,
          constraints: const BoxConstraints(minHeight: 160),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: reduceMotion ? Duration.zero : AppMotion.base,
                        curve: AppMotion.standard,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.brand.withValues(alpha: 0.08)
                              : palette.surfaceMuted,
                          borderRadius: AppRadii.rMd,
                          border: Border.all(
                            color: isSelected ? palette.brand : palette.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: _buildContent(emoji ?? fallbackEmoji, palette),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: -8,
                      child: _AddStepperButton(
                        count: effectiveCount,
                        onIncrement: onIncrement ?? onTap,
                        onDecrement: onDecrement,
                        reduceMotion: reduceMotion,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              if (showVegBadge) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: VegBadge(isVeg: isVeg, size: 14),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                name,
                style: context.text.labelMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasValidServingSize) ...[
                const SizedBox(height: 2),
                Text(
                  servingSize!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    color: palette.textTertiary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddStepperButton extends StatelessWidget {
  const _AddStepperButton({
    required this.count,
    this.onIncrement,
    this.onDecrement,
    required this.reduceMotion,
  });

  final int count;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (count == 0) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onIncrement?.call();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppMotion.base,
          curve: AppMotion.standard,
          height: 28,
          constraints: const BoxConstraints(minWidth: 54),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: palette.brand,
              width: 1.4,
            ),
            boxShadow: context.shadows.sm,
          ),
          alignment: Alignment.center,
          child: Text(
            'ADD',
            style: TextStyle(
              color: palette.brand,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : AppMotion.base,
      curve: AppMotion.standard,
      height: 28,
      decoration: BoxDecoration(
        color: palette.brand,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.brand, width: 1.4),
        boxShadow: context.shadows.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onDecrement?.call();
            },
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                Icons.remove_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onIncrement?.call();
            },
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                Icons.add_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Snack variant of [FoodCard].
class SnackCard extends FoodCard {
  const SnackCard({
    super.key,
    required super.name,
    required super.isVeg,
    required super.selected,
    super.count,
    super.emoji,
    super.servingSize,
    super.onTap,
    super.onIncrement,
    super.onDecrement,
  }) : super(fallbackEmoji: '🍽️');
}

/// Drink variant of [FoodCard].
class DrinkCard extends FoodCard {
  const DrinkCard({
    super.key,
    required super.name,
    required super.selected,
    super.isVeg = true,
    super.count,
    super.emoji,
    super.servingSize,
    super.onTap,
    super.onIncrement,
    super.onDecrement,
  }) : super(fallbackEmoji: '🥤', showVegBadge: false);
}
