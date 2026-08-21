import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/food_assets.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/app_tokens.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../data/local/app_database.dart';
import 'drink_dispenser_models.dart';

/// A compact curved drink selector with transparent PNG drink icons, drink names below,
/// faded side edges, and a centered compact action row (Sugar switch + Add / Stepper button).
class DrinkCarousel extends StatefulWidget {
  const DrinkCarousel({
    super.key,
    required this.drinks,
    required this.selectedIndex,
    required this.onDrinkSelected,
    required this.isSugarFree,
    required this.onSugarFreeChanged,
    required this.selectedSnackIds,
    required this.onIncrement,
    required this.onDecrement,
    this.format = DrinkFormat.coldJuice,
    this.disabled = false,
  });

  final List<LocalSnack> drinks;
  final int selectedIndex;
  final ValueChanged<int> onDrinkSelected;
  final bool isSugarFree;
  final ValueChanged<bool> onSugarFreeChanged;
  final List<String> selectedSnackIds;
  final ValueChanged<LocalSnack> onIncrement;
  final ValueChanged<LocalSnack> onDecrement;
  final DrinkFormat format;
  final bool disabled;

  @override
  State<DrinkCarousel> createState() => _DrinkCarouselState();
}

class _DrinkCarouselState extends State<DrinkCarousel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected(animate: false));
  }

  @override
  void didUpdateWidget(covariant DrinkCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelected(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected({bool animate = true}) {
    if (!_scrollController.hasClients || widget.drinks.isEmpty) return;
    const itemWidth = 72.0;
    const itemGap = 10.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemIndex = widget.selectedIndex.clamp(0, widget.drinks.length - 1);
    final target = (itemIndex * (itemWidth + itemGap)) - (screenWidth / 2) + (itemWidth / 2) + AppSpacing.page;

    final clamped = target.clamp(0.0, _scrollController.position.maxScrollExtent);
    if (animate) {
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.drinks.isEmpty) return const SizedBox.shrink();

    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = widget.disabled;

    final activeIndex = widget.selectedIndex.clamp(0, widget.drinks.length - 1);
    final activeDrink = widget.drinks.isNotEmpty && widget.selectedIndex >= 0
        ? widget.drinks[activeIndex]
        : null;
    final activeCount = activeDrink != null
        ? widget.selectedSnackIds.where((id) => id == activeDrink.id).length
        : 0;

    final isCan = widget.format == DrinkFormat.can;

    final disabledBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final disabledBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final disabledText = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Horizontal Dial with Circular Drink Icons and Names Below (Faded Sides)
        SizedBox(
          height: 92,
          width: double.infinity,
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.10, 0.90, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page * 2),
              physics: const BouncingScrollPhysics(),
              itemCount: widget.drinks.length,
              separatorBuilder: (context, index) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final drink = widget.drinks[index];
                final isSelected = index == widget.selectedIndex;

                return _DrinkItemButton(
                  drink: drink,
                  isSelected: isSelected,
                  onTap: () => widget.onDrinkSelected(index),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Centered Compact Action Controls (No full-width box!)
        if (activeDrink != null)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sugar-Free Toggle (ONLY for hot and cold drinks, NOT for cans)
                if (!isCan) ...[
                  PressableScale(
                    scale: disabled ? 1.0 : 0.95,
                    onTap: disabled
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            widget.onSugarFreeChanged(!widget.isSugarFree);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: disabled
                            ? disabledBg
                            : (widget.isSugarFree
                                ? palette.brand
                                : (isDark ? const Color(0xFF1E293B) : Colors.white)),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: disabled
                              ? disabledBorder
                              : (widget.isSugarFree
                                  ? palette.brand
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                          width: 1.4,
                        ),
                        boxShadow: disabled
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isSugarFree ? Symbols.check_rounded : Symbols.close_rounded,
                            size: 14,
                            color: disabled
                                ? disabledText
                                : (widget.isSugarFree ? Colors.white : palette.textSecondary),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.isSugarFree ? '0 SUGAR' : 'SUGAR',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: disabled
                                  ? disabledText
                                  : (widget.isSugarFree ? Colors.white : palette.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Centered ADD / Quantity Stepper Button
                if (activeCount > 0)
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: disabled ? disabledBg : null,
                      gradient: disabled
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: palette.headerGradient,
                            ),
                      borderRadius: BorderRadius.circular(19),
                      border: disabled ? Border.all(color: disabledBorder) : null,
                      boxShadow: disabled
                          ? null
                          : [
                              BoxShadow(
                                color: palette.brand.withValues(alpha: isDark ? 0.35 : 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove,
                            size: 16,
                            color: disabled ? disabledText : Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          constraints: const BoxConstraints(),
                          onPressed: disabled
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  widget.onDecrement(activeDrink);
                                },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '$activeCount',
                            style: TextStyle(
                              color: disabled ? disabledText : Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add,
                            size: 16,
                            color: disabled ? disabledText : Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          constraints: const BoxConstraints(),
                          onPressed: disabled
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  widget.onIncrement(activeDrink);
                                },
                        ),
                      ],
                    ),
                  )
                else
                  (disabled
                      ? Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: disabledBg,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(color: disabledBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Symbols.add_rounded, size: 16, color: disabledText),
                              const SizedBox(width: 6),
                              Text(
                                'ADD',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: disabledText,
                                ),
                              ),
                            ],
                          ),
                        )
                      : PressableScale(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onIncrement(activeDrink);
                          },
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: palette.headerGradient,
                              ),
                              borderRadius: BorderRadius.circular(19),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.brand.withValues(alpha: isDark ? 0.40 : 0.30),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Symbols.add_rounded, size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'ADD',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
              ],
            ),
          ),
      ],
    );
  }
}

class _DrinkItemButton extends StatelessWidget {
  const _DrinkItemButton({
    required this.drink,
    required this.isSelected,
    required this.onTap,
  });

  final LocalSnack drink;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final presentation = DrinkPresentation.fromSnack(drink);
    final assetPath = resolveLocalFoodAsset(drink.name);

    return PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Icon Capsule
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isSelected ? 52 : 44,
              height: isSelected ? 52 : 44,
              decoration: BoxDecoration(
                color: isDark ? palette.surface : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? palette.brand
                      : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 2.3 : 1.2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: palette.brand.withValues(alpha: isDark ? 0.45 : 0.30),
                      blurRadius: 13,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: assetPath != null
                      ? Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            presentation.iconData,
                            size: 23,
                            color: presentation.primaryColor,
                          ),
                        )
                      : Icon(
                          presentation.iconData,
                          size: 23,
                          color: presentation.primaryColor,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 5),

            // Drink Name Label Below
            Text(
              drink.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? palette.brand : palette.textPrimary,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
