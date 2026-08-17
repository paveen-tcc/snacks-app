import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/app_theme.dart';
import '../design/app_tokens.dart';
import 'app_buttons.dart' show PressableScale;

/// One entry in the [CategoryScroller].
class CategoryItem {
  const CategoryItem({
    required this.key,
    required this.label,
    this.icon,
    this.selectedIcon,
    this.emoji,
  });

  final String key;
  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
  final String? emoji;
}

/// A horizontally scrolling row of category tabs with icons and a full-width
/// continuous orange baseline indicator (Blinkit / Zepto style).
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
    final palette = context.palette;
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Full end-to-end orange baseline spanning the entire screen width
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 2.0,
              color: palette.brand,
            ),
          ),
          // Scrollable category tabs
          ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: padding,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return CategoryChip(
                label: item.label,
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                emoji: item.emoji,
                selected: item.key == selectedKey,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(item.key);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    this.icon,
    this.selectedIcon,
    this.emoji,
    this.onTap,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final IconData? selectedIcon;
  final String? emoji;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final activeColor = palette.brand;
    final inactiveColor = palette.textTertiary;

    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: CustomPaint(
          painter: _CurvedTabIndicatorPainter(
            selected: selected,
            activeColor: activeColor,
            backgroundColor: palette.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: icon != null || selectedIcon != null
                        ? Icon(
                            selected
                                ? (selectedIcon ?? icon ?? Icons.restaurant_rounded)
                                : (icon ?? selectedIcon ?? Icons.restaurant_outlined),
                            key: ValueKey('${label}_$selected'),
                            size: 22,
                            fill: selected ? 1.0 : 0.0,
                            color: selected ? activeColor : inactiveColor,
                          )
                        : (emoji != null
                            ? Text(
                                emoji!,
                                key: ValueKey('${label}_emoji'),
                                style: const TextStyle(fontSize: 18),
                              )
                            : Icon(
                                selected
                                    ? Icons.restaurant_rounded
                                    : Icons.restaurant_outlined,
                                key: ValueKey('${label}_$selected'),
                                size: 22,
                                fill: selected ? 1.0 : 0.0,
                                color: selected ? activeColor : inactiveColor,
                              )),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: context.text.labelSmall!.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? activeColor : palette.textSecondary,
                    fontSize: 11,
                    letterSpacing: 0.1,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurvedTabIndicatorPainter extends CustomPainter {
  const _CurvedTabIndicatorPainter({
    required this.selected,
    required this.activeColor,
    required this.backgroundColor,
  });

  final bool selected;
  final Color activeColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (!selected) return;

    final y = size.height - 1.0;
    const r = 6.0;
    const pad = 2.0;
    final left = pad;
    final right = size.width - pad;
    final topY = y - 5.0;

    // Mask out the straight baseline under the arched notch
    final maskPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(left + 1.0, y), Offset(right - 1.0, y), maskPaint);

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, y);
    path.lineTo(left, y);
    path.cubicTo(
      left + r * 0.4,
      y,
      left + r * 0.6,
      topY,
      left + r,
      topY,
    );
    path.lineTo(right - r, topY);
    path.cubicTo(
      right - r * 0.6,
      topY,
      right - r * 0.4,
      y,
      right,
      y,
    );
    path.lineTo(size.width, y);

    canvas.drawPath(path, activePaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedTabIndicatorPainter oldDelegate) {
    return oldDelegate.selected != selected ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
