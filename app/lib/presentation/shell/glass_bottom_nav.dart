import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/app_theme.dart';

class NavDestinationData {
  const NavDestinationData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// A floating solid capsule navigation bar with a single gliding indicator.
/// Expands the active tab smoothly so words are never cut off.
class GlassBottomNav extends StatefulWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
  }) : assert(destinations.length > 0);

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavDestinationData> destinations;

  @override
  State<GlassBottomNav> createState() => _GlassBottomNavState();
}

class _GlassBottomNavState extends State<GlassBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _indicatorController;
  late double _indicatorIndex;
  late double _animationStart;
  late double _animationTarget;

  double _inactiveWidth = 1;
  bool _isDragging = false;
  int? _lastDragIndex;

  int _safeIndex(int index) {
    return math.max(0, math.min(index, widget.destinations.length - 1));
  }

  @override
  void initState() {
    super.initState();
    _indicatorIndex = _safeIndex(widget.currentIndex).toDouble();
    _animationStart = _indicatorIndex;
    _animationTarget = _indicatorIndex;
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(_tickIndicator);
  }

  @override
  void didUpdateWidget(covariant GlassBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _safeIndex(widget.currentIndex).toDouble();
    if (!_isDragging && (_animationTarget - target).abs() > 0.001) {
      _animateIndicatorTo(target);
    }
  }

  @override
  void dispose() {
    _indicatorController
      ..removeListener(_tickIndicator)
      ..dispose();
    super.dispose();
  }

  void _tickIndicator() {
    final progress = Curves.easeOutCubic.transform(_indicatorController.value);
    setState(() {
      _indicatorIndex =
          _animationStart + (_animationTarget - _animationStart) * progress;
    });
  }

  void _animateIndicatorTo(double target) {
    final clampedTarget = target.clamp(
      0.0,
      (widget.destinations.length - 1).toDouble(),
    );
    _indicatorController.stop();

    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      setState(() {
        _indicatorIndex = clampedTarget;
        _animationStart = clampedTarget;
        _animationTarget = clampedTarget;
      });
      return;
    }

    _animationStart = _indicatorIndex;
    _animationTarget = clampedTarget;
    _indicatorController.forward(from: 0);
  }

  void _selectIndex(int index) {
    final target = _safeIndex(index);
    _animateIndicatorTo(target.toDouble());
    if (target == widget.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.onTap(target);
  }

  void _handleDragStart(DragStartDetails details) {
    _indicatorController.stop();
    setState(() => _isDragging = true);
    _lastDragIndex = _indicatorIndex.round();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final maxIndex = (widget.destinations.length - 1).toDouble();
    final nextIndex = (_indicatorIndex + details.delta.dx / _inactiveWidth)
        .clamp(0.0, maxIndex);
    final nearestIndex = nextIndex.round();
    if (nearestIndex != _lastDragIndex) {
      _lastDragIndex = nearestIndex;
      HapticFeedback.selectionClick();
    }
    setState(() => _indicatorIndex = nextIndex);
  }

  void _handleDragEnd(DragEndDetails details) {
    final target = _safeIndex(_indicatorIndex.round());
    setState(() => _isDragging = false);
    _animateIndicatorTo(target.toDouble());
    if (target != widget.currentIndex) {
      widget.onTap(target);
    }
  }

  void _handleDragCancel() {
    setState(() => _isDragging = false);
    _animateIndicatorTo(_safeIndex(widget.currentIndex).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = palette.isDark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final itemDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 320);
    final count = widget.destinations.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(bottomInset, 4)),
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1D24) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? palette.border : const Color(0xFFE8E8E8),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final innerWidth = constraints.maxWidth;
            const activeFlex = 1.95;
            const inactiveFlex = 1.0;
            final totalFlex = activeFlex + (count - 1) * inactiveFlex;

            final activeWidth = innerWidth * (activeFlex / totalFlex);
            final inactiveWidth = innerWidth * (inactiveFlex / totalFlex);
            _inactiveWidth = inactiveWidth;
            final activeLeft = _indicatorIndex * inactiveWidth;
            final indicatorContentIndex = _safeIndex(
              (_isDragging ? _indicatorIndex : _animationTarget).round(),
            );

            final activeBg = palette.brand;
            const activeFg = Colors.white;
            final inactiveFg = isDark
                ? const Color(0xFF8E8E98)
                : const Color(0xFF64748B);

            return GestureDetector(
              key: const ValueKey('bottom_nav_drag_surface'),
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onHorizontalDragStart: _handleDragStart,
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              onHorizontalDragCancel: _handleDragCancel,
              child: Stack(
                children: [
                  // Inactive icons stay behind the moving selected pill.
                  Row(
                    children: [
                      for (var i = 0; i < count; i++)
                        AnimatedContainer(
                          key: ValueKey('bottom_nav_item_$i'),
                          duration: itemDuration,
                          curve: Curves.easeOutCubic,
                          width: i == widget.currentIndex
                              ? activeWidth
                              : inactiveWidth,
                          height: 48,
                          child: Semantics(
                            button: true,
                            selected: i == widget.currentIndex,
                            label: widget.destinations[i].label,
                            child: GestureDetector(
                              onTap: () => _selectIndex(i),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Icon(
                                  widget.destinations[i].icon,
                                  key: ValueKey('inactive_$i'),
                                  size: 20,
                                  color: inactiveFg,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // The selected icon and label travel inside the solid pill.
                  Positioned(
                    left: activeLeft,
                    top: 0,
                    bottom: 0,
                    width: activeWidth,
                    child: IgnorePointer(
                      child: Container(
                        key: const ValueKey('bottom_nav_indicator'),
                        decoration: BoxDecoration(
                          color: activeBg,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: activeBg.withValues(
                                alpha: isDark ? 0.35 : 0.25,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 160),
                            child: Padding(
                              key: ValueKey(
                                'indicator_content_$indicatorContentIndex',
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget
                                        .destinations[indicatorContentIndex]
                                        .selectedIcon,
                                    key: ValueKey(
                                      'active_icon_$indicatorContentIndex',
                                    ),
                                    size: 19,
                                    color: activeFg,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      widget
                                          .destinations[indicatorContentIndex]
                                          .label,
                                      maxLines: 1,
                                      overflow: TextOverflow.visible,
                                      softWrap: false,
                                      style: const TextStyle(
                                        color: activeFg,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
