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

/// A horizontally scrolling row of category tabs with icons and a continuous
/// sliding arched baseline indicator that fluidly glides between selected tabs.
class CategoryScroller extends StatefulWidget {
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
  State<CategoryScroller> createState() => _CategoryScrollerState();
}

class _CategoryScrollerState extends State<CategoryScroller> {
  final Map<String, GlobalKey> _itemKeys = {};
  final GlobalKey _rowKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  double _indicatorLeft = 0.0;
  double _indicatorWidth = 80.0;
  bool _hasMeasured = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      _itemKeys[item.key] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator(animateScroll: false));
  }

  @override
  void didUpdateWidget(covariant CategoryScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final item in widget.items) {
      _itemKeys.putIfAbsent(item.key, () => GlobalKey());
    }
    if (oldWidget.selectedKey != widget.selectedKey || oldWidget.items != widget.items) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator(animateScroll: true));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateIndicator({bool animateScroll = true}) {
    final chipKey = _itemKeys[widget.selectedKey];
    if (chipKey?.currentContext == null || _rowKey.currentContext == null) return;

    final chipBox = chipKey!.currentContext!.findRenderObject() as RenderBox?;
    final rowBox = _rowKey.currentContext!.findRenderObject() as RenderBox?;
    if (chipBox == null || rowBox == null) return;

    final localOffset = rowBox.globalToLocal(chipBox.localToGlobal(Offset.zero));
    final width = chipBox.size.width;
    final left = localOffset.dx;

    setState(() {
      _indicatorLeft = left;
      _indicatorWidth = width;
      _hasMeasured = true;
    });

    if (animateScroll && _scrollController.hasClients) {
      final parentBox = context.findRenderObject() as RenderBox?;
      final viewportWidth = parentBox?.size.width ?? 360.0;
      final targetScroll = (left - (viewportWidth / 2) + (width / 2))
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      height: 56,
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

          // Scrollable category tabs with sliding arched indicator
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: widget.padding,
            physics: const BouncingScrollPhysics(),
            child: Stack(
              children: [
                // Gliding Arched Indicator underneath
                if (_hasMeasured)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    left: _indicatorLeft,
                    bottom: 0,
                    width: _indicatorWidth,
                    height: 56,
                    child: CustomPaint(
                      painter: _CurvedTabIndicatorPainter(
                        activeColor: palette.brand,
                        backgroundColor: palette.surface,
                      ),
                    ),
                  ),

                // Category Chips Row
                Row(
                  key: _rowKey,
                  children: [
                    for (var i = 0; i < widget.items.length; i++) ...[
                      () {
                        final item = widget.items[i];
                        final isSelected = item.key == widget.selectedKey;
                        return CategoryChip(
                          key: _itemKeys[item.key],
                          label: item.label,
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          emoji: item.emoji,
                          selected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onSelected(item.key);
                          },
                        );
                      }(),
                    ],
                  ],
                ),
              ],
            ),
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
      child: Container(
        height: 56,
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: icon != null || selectedIcon != null
                    ? Icon(
                        selected
                            ? (selectedIcon ?? icon ?? Icons.restaurant_rounded)
                            : (icon ?? selectedIcon ?? Icons.restaurant_outlined),
                        key: ValueKey('${label}_$selected'),
                        size: selected ? 20 : 18,
                        fill: selected ? 1.0 : 0.0,
                        color: selected ? activeColor : inactiveColor,
                      )
                    : (emoji != null
                        ? Text(
                            emoji!,
                            key: ValueKey('${label}_emoji'),
                            style: const TextStyle(fontSize: 16),
                          )
                        : Icon(
                            selected
                                ? Icons.restaurant_rounded
                                : Icons.restaurant_outlined,
                            key: ValueKey('${label}_$selected'),
                            size: selected ? 20 : 18,
                            fill: selected ? 1.0 : 0.0,
                            color: selected ? activeColor : inactiveColor,
                          )),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 240),
              style: context.text.labelSmall!.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : palette.textSecondary,
                fontSize: 11.5,
                letterSpacing: 0.1,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvedTabIndicatorPainter extends CustomPainter {
  const _CurvedTabIndicatorPainter({
    required this.activeColor,
    required this.backgroundColor,
  });

  final Color activeColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - 1.0;
    const r = 5.0;
    const pad = 2.0;
    final left = pad;
    final right = size.width - pad;
    final topY = y - 4.5;

    // Mask out the straight baseline under the arched notch
    final maskPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(left + 1.0, y), Offset(right - 1.0, y), maskPaint);

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.4
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
    return oldDelegate.activeColor != activeColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
