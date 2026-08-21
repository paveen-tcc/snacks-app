import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/food_assets.dart';
import '../design/app_colors.dart';
import '../design/app_theme.dart';
import '../design/app_tokens.dart';
import 'app_buttons.dart' show PressableScale;

/// Clean card displaying a snack or beverage.
///
/// Has a solid image container, veg/non-veg badge, name, serving size, and
/// a bottom stepper button that smoothly animates to full width when selected.
class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.name,
    this.isVeg = true,
    this.servingSize,
    this.imageUrl,
    this.emoji,
    this.fallbackEmoji = '🍽️',
    this.selected = false,
    this.count,
    this.onTap,
    this.onIncrement,
    this.onDecrement,
    this.showVegBadge = true,
    this.disabled = false,
  });

  final String name;
  final bool isVeg;
  final String? servingSize;
  final String? imageUrl;
  final String? emoji;
  final String fallbackEmoji;
  final bool selected;
  final int? count;
  final VoidCallback? onTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool showVegBadge;
  final bool disabled;

  int get effectiveCount => count ?? (selected ? 1 : 0);
  bool get isSelected => effectiveCount > 0;

  void _handleTap() {
    if (disabled) return;
    if (effectiveCount == 0) {
      HapticFeedback.selectionClick();
      if (onIncrement != null) {
        onIncrement!();
      } else {
        onTap?.call();
      }
    }
  }

  Widget _buildContent(String effectiveEmoji, AppPalette palette) {
    // 1. Check for local bundled transparent PNG asset first
    final localAsset = resolveLocalFoodAsset(name) ??
        (imageUrl != null && imageUrl!.trim().startsWith('assets/')
            ? imageUrl!.trim()
            : null);

    if (localAsset != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Image.asset(
          localAsset,
          fit: BoxFit.contain,
          cacheWidth: 360,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.fastfood_rounded,
            size: 34,
            color: const Color(0xFF9A9AA0).withValues(alpha: 0.6),
          ),
        ),
      );
    }

    // 2. Check if we have a valid image URL either from imageUrl or passed as emoji
    String? validUrl;
    if (imageUrl != null && imageUrl!.trim().startsWith('http')) {
      validUrl = imageUrl!.trim();
    } else if (effectiveEmoji.trim().startsWith('http')) {
      validUrl = effectiveEmoji.trim();
    }

    if (validUrl != null) {
      return ClipRRect(
        borderRadius: AppRadii.rMd,
        child: CachedNetworkImage(
          imageUrl: validUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Container(
            alignment: Alignment.center,
            child: Icon(
              Icons.fastfood_rounded,
              size: 34,
              color: const Color(0xFF9A9AA0).withValues(alpha: 0.6),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            alignment: Alignment.center,
            child: Icon(
              Icons.fastfood_rounded,
              size: 34,
              color: const Color(0xFF9A9AA0).withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    // 3. If it is a clean short emoji, render the emoji
    if (effectiveEmoji.isNotEmpty &&
        !effectiveEmoji.startsWith('http') &&
        effectiveEmoji.length <= 4) {
      return Text(
        effectiveEmoji,
        style: const TextStyle(fontSize: 38),
      );
    }

    // 4. Fallback: Default clean centered icon
    return Container(
      alignment: Alignment.center,
      child: Icon(
        Icons.fastfood_rounded,
        size: 36,
        color: const Color(0xFF9A9AA0).withValues(alpha: 0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = palette.isDark;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final hasValidServingSize =
        servingSize != null &&
        servingSize!.isNotEmpty &&
        servingSize != '1' &&
        servingSize != '1 serving';

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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: AnimatedContainer(
                            duration:
                                reduceMotion ? Duration.zero : AppMotion.base,
                            curve: AppMotion.standard,
                            decoration: BoxDecoration(
                              // Clean white background with soft blue circular gradient light
                              color: isDark ? palette.surface : Colors.white,
                              gradient: isSelected
                                  ? RadialGradient(
                                      center: const Alignment(0, 0.05),
                                      radius: 0.85,
                                      colors: isDark
                                          ? [
                                              palette.brand.withValues(alpha: 0.25),
                                              palette.surface,
                                            ]
                                          : [
                                              palette.brand.withValues(alpha: 0.14),
                                              const Color(0xFFF2F7FD),
                                              Colors.white,
                                            ],
                                      stops: isDark ? const [0.0, 1.0] : const [0.0, 0.6, 1.0],
                                    )
                                  : RadialGradient(
                                      center: const Alignment(0, 0.05),
                                      radius: 0.82,
                                      colors: palette.cardGlowGradient,
                                      stops: isDark ? const [0.0, 0.55, 1.0] : const [0.0, 0.55, 1.0],
                                    ),
                              borderRadius: AppRadii.rMd,
                              border: Border.all(
                                color: isSelected
                                    ? palette.brand
                                    : (isDark
                                        ? palette.border
                                        : const Color(0xFFE5ECF6)),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF003874).withValues(
                                    alpha: isDark ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child:
                                _buildContent(emoji ?? fallbackEmoji, palette),
                          ),
                        ),
                        // Smoothly animated stepper position and width
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          left: isSelected ? 4 : cardWidth - 62,
                          right: 4,
                          bottom: -8,
                          child: _AddStepperButton(
                            count: effectiveCount,
                            onIncrement: disabled ? null : (onIncrement ?? onTap),
                            onDecrement: disabled ? null : onDecrement,
                            reduceMotion: reduceMotion,
                            disabled: disabled,
                          ),
                        ),
                      ],
                    );
                  },
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
                  color: disabled
                      ? palette.textSecondary
                      : palette.textPrimary,
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
    this.disabled = false,
  });

  final int count;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool reduceMotion;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = palette.isDark;
    final isSelected = count > 0;

    final backgroundColor = disabled
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
        : (isSelected
            ? palette.brand
            : (isDark ? palette.surface : Colors.white));

    final borderColor = disabled
        ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
        : (isSelected
            ? palette.brand
            : (isDark ? palette.border : const Color(0xFFE2E8F0)));

    final textColor = disabled
        ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
        : (isSelected
            ? Colors.white
            : palette.brand);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      height: 30,
      decoration: BoxDecoration(
        // Solid fill at all times so there is zero transparent flicker during expansion
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: disabled ? null : context.shadows.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isSelected
              ? Row(
                  key: const ValueKey('stepper_active'),
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!disabled)
                      PressableScale(
                        scale: 0.85,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onDecrement?.call();
                        },
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Icon(
                            Icons.remove_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 16,
                          color: textColor,
                        ),
                      ),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: disabled ? textColor : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                    if (!disabled)
                      PressableScale(
                        scale: 0.85,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onIncrement?.call();
                        },
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: textColor,
                        ),
                      ),
                  ],
                )
              : (disabled
                  ? Container(
                      key: const ValueKey('stepper_disabled'),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      child: Text(
                        'ADD',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.4,
                        ),
                      ),
                    )
                  : PressableScale(
                      key: const ValueKey('stepper_idle'),
                      scale: 0.90,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onIncrement?.call();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        child: Text(
                          'ADD',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    )),
        ),
      ),
    );
  }
}

/// Snack variant of [FoodCard].
class SnackCard extends FoodCard {
  const SnackCard({
    super.key,
    required super.name,
    super.isVeg = true,
    super.servingSize,
    super.imageUrl,
    super.emoji,
    super.fallbackEmoji = '🍿',
    super.selected = false,
    super.count,
    super.onTap,
    super.onIncrement,
    super.onDecrement,
    super.showVegBadge = true,
    super.disabled = false,
  });
}

/// Drink variant of [FoodCard].
class DrinkCard extends FoodCard {
  const DrinkCard({
    super.key,
    required super.name,
    super.isVeg = true,
    super.servingSize,
    super.imageUrl,
    super.emoji,
    super.fallbackEmoji = '🥤',
    super.selected = false,
    super.count,
    super.onTap,
    super.onIncrement,
    super.onDecrement,
    super.showVegBadge = true,
    super.disabled = false,
  });
}

/// Veg badge with official green dot in green square.
class VegBadge extends StatelessWidget {
  const VegBadge({
    super.key,
    required this.isVeg,
    this.size = 14,
    this.color,
  });

  final bool isVeg;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isVeg ? context.palette.veg : context.palette.nonVeg);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: effectiveColor, width: 1.2),
      ),
      alignment: Alignment.center,
      child: isVeg
          ? Container(
              width: size * 0.44,
              height: size * 0.44,
              decoration: BoxDecoration(
                color: effectiveColor,
                shape: BoxShape.circle,
              ),
            )
          : CustomPaint(
              size: Size(size * 0.5, size * 0.5),
              painter: _TrianglePainter(color: effectiveColor),
            ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
