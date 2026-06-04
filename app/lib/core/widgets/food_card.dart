import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/app_theme.dart';
import '../design/app_tokens.dart';

/// The Swiggy/Zomato-style veg/non-veg indicator: a bordered square with a
/// center dot (green = veg, red = non-veg).
class VegBadge extends StatelessWidget {
  const VegBadge({super.key, required this.isVeg, this.size = 16});

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
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Container(
            width: size * 0.42,
            height: size * 0.42,
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
    this.description,
    this.emoji,
    this.servingSize,
    this.onTap,
    this.fallbackEmoji = '🍽️',
    this.showVegBadge = true,
  });

  final String name;
  final bool isVeg;
  final bool selected;
  final String? description;
  final String? emoji;
  final String? servingSize;
  final VoidCallback? onTap;
  final String fallbackEmoji;
  final bool showVegBadge;

  void _handleTap() {
    HapticFeedback.selectionClick();
    onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final metaLabel = showVegBadge ? (isVeg ? 'Veg' : 'Non-veg') : 'Drink';

    return Semantics(
      button: true,
      selected: selected,
      label: '$name, $metaLabel${selected ? ', added' : ''}',
      child: GestureDetector(
        onTap: onTap == null ? null : _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppMotion.base,
          curve: AppMotion.standard,
          constraints: const BoxConstraints(minHeight: 216),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: AppRadii.rMd,
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
                          color: selected
                              ? palette.brand.withValues(alpha: 0.08)
                              : palette.surfaceMuted,
                          borderRadius: AppRadii.rMd,
                          border: Border.all(
                            color: selected ? palette.brand : palette.border,
                            width: selected ? 1.4 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji ?? fallbackEmoji,
                          style: const TextStyle(fontSize: 38),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: -6,
                      child: _AddButton(
                        selected: selected,
                        reduceMotion: reduceMotion,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (showVegBadge)
                    VegBadge(isVeg: isVeg, size: 13)
                  else
                    Icon(
                      Icons.local_cafe_rounded,
                      size: 13,
                      color: palette.textSecondary,
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      metaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(
                        color: showVegBadge
                            ? (isVeg ? palette.veg : palette.nonVeg)
                            : palette.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
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
              if (servingSize != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: double.infinity,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: AppRadii.rSm,
                      border: Border.all(color: palette.border),
                    ),
                    child: Text(
                      servingSize!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(
                        color: palette.brand,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
              if ((description ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description!,
                  style: context.text.labelSmall?.copyWith(
                    color: palette.textSecondary,
                    height: 1.15,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.selected, required this.reduceMotion});

  final bool selected;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : AppMotion.base,
      curve: AppMotion.standard,
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: selected ? palette.brand : palette.surface,
        borderRadius: AppRadii.rSm,
        border: Border.all(
          color: selected
              ? palette.brand
              : palette.brand.withValues(alpha: 0.72),
          width: 1.4,
        ),
        boxShadow: context.shadows.sm,
      ),
      alignment: Alignment.center,
      child: Icon(
        selected ? Icons.check_rounded : Icons.add_rounded,
        size: 23,
        color: selected ? palette.onBrand : palette.brand,
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
    super.description,
    super.emoji,
    super.servingSize,
    super.onTap,
  }) : super(fallbackEmoji: '🍽️');
}

/// Drink variant of [FoodCard].
class DrinkCard extends FoodCard {
  const DrinkCard({
    super.key,
    required super.name,
    required super.selected,
    super.isVeg = true,
    super.description,
    super.emoji,
    super.servingSize,
    super.onTap,
  }) : super(fallbackEmoji: '🥤', showVegBadge: false);
}
