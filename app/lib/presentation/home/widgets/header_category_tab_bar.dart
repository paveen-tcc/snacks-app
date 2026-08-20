import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart' show PressableScale;

/// Item model for [HeaderCategoryTabBar].
class HeaderTabItem<T> {
  const HeaderTabItem({
    required this.value,
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
  });

  final T value;
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
}

/// Shared category & format tab bar used across Food & Drinks headers.
/// Features a continuous baseline across the screen and an animated gliding
/// arched trapezoid notch over the active tab item.
class HeaderCategoryTabBar<T> extends StatefulWidget {
  const HeaderCategoryTabBar({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.isScrolled = false,
  });

  final List<HeaderTabItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final bool isScrolled;

  @override
  State<HeaderCategoryTabBar<T>> createState() =>
      _HeaderCategoryTabBarState<T>();
}

class _HeaderCategoryTabBarState<T> extends State<HeaderCategoryTabBar<T>> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _rowKey = GlobalKey();
  final Map<T, GlobalKey> _itemKeys = {};

  double _indicatorLeft = 0;
  double _indicatorWidth = 0;
  bool _hasMeasured = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      _itemKeys[item.value] = GlobalKey();
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateIndicator(animateScroll: false));
  }

  @override
  void didUpdateWidget(covariant HeaderCategoryTabBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final item in widget.items) {
      _itemKeys.putIfAbsent(item.value, () => GlobalKey());
    }
    if (oldWidget.selectedValue != widget.selectedValue ||
        oldWidget.items != widget.items) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _updateIndicator(animateScroll: true));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateIndicator({bool animateScroll = true}) {
    final chipKey = _itemKeys[widget.selectedValue];
    if (chipKey?.currentContext == null || _rowKey.currentContext == null) {
      return;
    }

    final chipBox = chipKey!.currentContext!.findRenderObject() as RenderBox?;
    final rowBox = _rowKey.currentContext!.findRenderObject() as RenderBox?;
    if (chipBox == null || rowBox == null) return;

    final localOffset =
        rowBox.globalToLocal(chipBox.localToGlobal(Offset.zero));
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
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScrolled = widget.isScrolled;

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Full-width baseline across the header in solid white
          Positioned(
            left: 0,
            right: 0,
            bottom: 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              height: 2.0,
              color: isScrolled ? const Color(0xFFE2E8F0) : Colors.white,
            ),
          ),

          // 2. Scrollable category items
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            physics: const BouncingScrollPhysics(),
            child: Stack(
              children: [
                // Gliding Arched Indicator Bridge
                if (_hasMeasured)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    left: _indicatorLeft,
                    bottom: 0,
                    width: _indicatorWidth,
                    height: 56,
                    child: CustomPaint(
                      painter: _HeaderArchedIndicatorPainter(
                        activeColor: isScrolled
                            ? context.palette.brand
                            : Colors.white,
                        bgColor: isScrolled
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? context.palette.surface
                                : Colors.white)
                            : context.palette.headerGradient.last,
                      ),
                    ),
                  ),

                // Category items row
                Row(
                  key: _rowKey,
                  children: [
                    for (final item in widget.items) ...[
                      () {
                        final isSelected = item.value == widget.selectedValue;
                        final icon = isSelected
                            ? item.selectedIcon
                            : item.unselectedIcon;

                        return PressableScale(
                          key: _itemKeys[item.value],
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onChanged(item.value);
                          },
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: isSelected ? 20 : 18,
                                  color: isSelected
                                      ? (isScrolled
                                          ? context.palette.brand
                                          : Colors.white)
                                      : (isScrolled
                                          ? const Color(0xFF64748B)
                                          : Colors.white.withValues(alpha: 0.72)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? (isScrolled
                                            ? context.palette.brand
                                            : Colors.white)
                                        : (isScrolled
                                            ? const Color(0xFF64748B)
                                            : Colors.white.withValues(alpha: 0.72)),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

/// Custom painter for the trapezoidal bridge notch resting on the baseline
class _HeaderArchedIndicatorPainter extends CustomPainter {
  const _HeaderArchedIndicatorPainter({
    required this.activeColor,
    required this.bgColor,
  });

  final Color activeColor;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final archWidth = (w * 0.65).clamp(24.0, 48.0);
    final startX = (w - archWidth) / 2;
    final endX = startX + archWidth;
    const cornerWidth = 5.0;
    const archHeight = 4.5;
    final baseY = h - 1.0;

    // 1. Erase/Mask the baseline beneath the arch using the header background color
    final maskPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    final maskPath = Path()
      ..moveTo(startX - 0.5, baseY + 1.0)
      ..lineTo(startX + cornerWidth, baseY - archHeight)
      ..lineTo(endX - cornerWidth, baseY - archHeight)
      ..lineTo(endX + 0.5, baseY + 1.0)
      ..close();

    canvas.drawPath(maskPath, maskPaint);

    // 2. Draw the elevated bridge arch outline
    final strokePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final strokePath = Path()
      ..moveTo(startX, baseY)
      ..lineTo(startX + cornerWidth, baseY - archHeight)
      ..lineTo(endX - cornerWidth, baseY - archHeight)
      ..lineTo(endX, baseY);

    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HeaderArchedIndicatorPainter oldDelegate) =>
      oldDelegate.activeColor != activeColor || oldDelegate.bgColor != bgColor;
}
