import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/app_theme.dart';
import '../design/app_tokens.dart';
import 'app_buttons.dart' show PressableScale;

/// One entry in the [CategoryScroller].
class CategoryItem {
  const CategoryItem({required this.key, required this.label, this.emoji});

  final String key;
  final String label;
  final String? emoji;
}

/// A horizontally scrolling row of pill category chips with a brand-filled
/// selected state (Swiggy/Zomato style).
class CategoryScroller extends StatelessWidget {
  const CategoryScroller({
    super.key,
    required this.items,
    required this.selectedKey,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.page),
  });

  final List<CategoryItem> items;
  final String selectedKey;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          return CategoryChip(
            label: item.label,
            emoji: item.emoji,
            selected: item.key == selectedKey,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(item.key);
            },
          );
        },
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    this.emoji,
    this.onTap,
  });

  final String label;
  final bool selected;
  final String? emoji;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? palette.brand : palette.surfaceMuted,
          borderRadius: AppRadii.rPill,
          border: Border.all(
            color: selected ? palette.brand : palette.border,
          ),
        ),
        child: Row(
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: selected ? palette.onBrand : palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
