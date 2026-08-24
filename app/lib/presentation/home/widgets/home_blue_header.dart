import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/snack_categories.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/glass.dart';
import '../../../core/widgets/food_card.dart' show VegBadge;
import '../bloc/home_bloc.dart';
import '../home_helpers.dart';
import 'header_category_tab_bar.dart';

/// Pinned Sticky Header Delegate for the Search Bar & Category Scroller.
/// Seamlessly morphs from blue gradient to frosted white glass when scrolling down.
class HomeStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  HomeStickyHeaderDelegate({
    required this.query,
    required this.onQueryChanged,
    required this.isVegMode,
    required this.onVegChanged,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.topPadding,
    required this.textScale,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final bool isVegMode;
  final ValueChanged<bool> onVegChanged;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final double topPadding;
  final double textScale;

  @override
  double get minExtent =>
      topPadding +
      6.0 +
      48.0 +
      10.0 +
      56.0 +
      ((textScale.clamp(1.0, 2.0) - 1) * 20) +
      2.0;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return HomeStickyTopBar(
      query: query,
      onQueryChanged: onQueryChanged,
      isVegMode: isVegMode,
      onVegChanged: onVegChanged,
      categories: categories,
      selectedCategory: selectedCategory,
      onCategorySelected: onCategorySelected,
      topPadding: topPadding,
      isScrolled: overlapsContent,
    );
  }

  @override
  bool shouldRebuild(covariant HomeStickyHeaderDelegate oldDelegate) {
    return oldDelegate.query != query ||
        oldDelegate.isVegMode != isVegMode ||
        oldDelegate.categories != categories ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.textScale != textScale;
  }
}

/// The Morphing Sticky Top Bar:
/// - At the top (isScrolled = false): Blue gradient with doodle vector overlay, solid white baseline & active arch.
/// - Scrolled down (isScrolled = true): Frosted white glass with drop shadow, slate divider, and accent blue active arch.
class HomeStickyTopBar extends StatefulWidget {
  const HomeStickyTopBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.isVegMode,
    required this.onVegChanged,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.topPadding,
    required this.isScrolled,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final bool isVegMode;
  final ValueChanged<bool> onVegChanged;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final double topPadding;
  final bool isScrolled;

  @override
  State<HomeStickyTopBar> createState() => _HomeStickyTopBarState();
}

class _HomeStickyTopBarState extends State<HomeStickyTopBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant HomeStickyTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _searchController.text) {
      _searchController.text = widget.query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerTopOffset = widget.topPadding + 6.0;
    final isScrolled = widget.isScrolled;

    return ClipRect(
      child: _OptionalHeaderBlur(
        enabled: isScrolled,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isScrolled ? Colors.white.withValues(alpha: 0.94) : null,
            gradient: isScrolled
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: context.palette.headerGradient,
                  ),
            boxShadow: isScrolled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Vector doodle overlay (visible only in blue mode)
              if (!isScrolled)
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/home/header_doodle_bg.svg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),

              // Content Column
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: headerTopOffset),

                  // 1. Search Bar + VEG toggle card
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.page,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Search bar container
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            height: 48,
                            decoration: BoxDecoration(
                              color: isScrolled
                                  ? const Color(0xFFF1F5F9)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: isScrolled
                                  ? Border.all(color: const Color(0xFFE2E8F0))
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isScrolled ? 0.03 : 0.08,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                widget.onQueryChanged(val);
                                setState(() {});
                              },
                              onTapOutside: (_) =>
                                  FocusScope.of(context).unfocus(),
                              textInputAction: TextInputAction.search,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: isScrolled
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF1C1C1E),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                fillColor: Colors.transparent,
                                hintText: 'Search snacks',
                                hintStyle: TextStyle(
                                  color: isScrolled
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF9A9AA0),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: isScrolled
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF6B6B70),
                                  size: 22,
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: isScrolled
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF9A9AA0),
                                          size: 18,
                                        ),
                                        splashRadius: 16,
                                        onPressed: () {
                                          _searchController.clear();
                                          widget.onQueryChanged('');
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // VEG Toggle Card
                        _VegToggleCard(
                          value: widget.isVegMode,
                          onChanged: widget.onVegChanged,
                          isScrolled: isScrolled,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. Category Scroller
                  HeaderCategoryTabBar<String>(
                    items: widget.categories.map((cat) {
                      final pair = snackCategoryIconPair(cat);
                      return HeaderTabItem<String>(
                        value: cat,
                        label: cat,
                        selectedIcon: pair.selected,
                        unselectedIcon: pair.unselected,
                      );
                    }).toList(),
                    selectedValue: widget.selectedCategory,
                    onChanged: widget.onCategorySelected,
                    isScrolled: isScrolled,
                  ),

                  const SizedBox(height: 2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionalHeaderBlur extends StatelessWidget {
  const _OptionalHeaderBlur({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled || !GlassCapability.blurEnabled(context)) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: child,
    );
  }
}

/// The Scrollable Blue Hero Banner (Timer, Grab a Bite, 3D Assets, Characters)
class HomeHeroBanner extends StatefulWidget {
  const HomeHeroBanner({super.key, required this.state, this.isActive = true});

  final HomeLoaded state;
  final bool isActive;

  @override
  State<HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<HomeHeroBanner>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _floatAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncActivity();
  }

  @override
  void didUpdateWidget(covariant HomeHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.cutoffTime != widget.state.cutoffTime ||
        oldWidget.state.advanceWindowEnd != widget.state.advanceWindowEnd ||
        oldWidget.state.advanceOrderMode != widget.state.advanceOrderMode ||
        oldWidget.isActive != widget.isActive) {
      _syncActivity();
    }
  }

  void _syncActivity() {
    final animate = widget.isActive && !_reduceMotion;
    if (animate && !_floatController.isAnimating) {
      _floatController.repeat(reverse: true);
    } else if (!animate && _floatController.isAnimating) {
      _floatController.stop();
    }
    if (_reduceMotion) _floatController.value = 0.5;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.isActive && !isOrderingClosed(widget.state)) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  Duration _getRemainingDuration() {
    if (isOrderingClosed(widget.state)) {
      return Duration.zero;
    }
    final now = DateTime.now();
    final targetTimeStr = widget.state.advanceOrderMode
        ? widget.state.advanceWindowEnd
        : widget.state.cutoffTime;

    final parts = targetTimeStr.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 16;
      final m = int.tryParse(parts[1]) ?? 0;
      final target = DateTime(now.year, now.month, now.day, h, m);
      final diff = target.difference(now);
      return diff.isNegative ? Duration.zero : diff;
    }

    return const Duration(hours: 1, minutes: 35, seconds: 1);
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = isOrderingClosed(widget.state);
    final remaining = _getRemainingDuration();
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          boxShadow: [
            if (isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 18,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: context.palette.brand.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: context.palette.heroBannerGradient,
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1.0,
                ),
              ),
            ),
            child: Stack(
              children: [
                // Background vector doodle overlay
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/home/header_doodle_bg.svg',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),

                // Animated floating burger (top-left)
                Positioned(
                  left: 6,
                  top: 14,
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 62,
                      height: 62,
                      child: Image.asset(
                        'assets/images/home/floating_burger.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),

                // Animated floating soda can (top-right)
                Positioned(
                  right: 6,
                  top: 16,
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_floatAnimation.value),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: Image.asset(
                        'assets/images/home/floating_soda.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),

                // Animated floating fruit basket (mid-left)
                Positioned(
                  left: 6,
                  top: 86,
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_floatAnimation.value * 0.8),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: Image.asset(
                        'assets/images/home/floating_fruits.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),

                // Animated floating coffee cup (mid-right)
                Positioned(
                  right: 6,
                  top: 88,
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value * 0.8),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.asset(
                        'assets/images/home/floating_coffee.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),

                // 3D Friends Illustration (Extends down to the container's bottom edge)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 0,
                  child: SizedBox(
                    height: 105,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: 0.65,
                        child: Image.asset(
                          'assets/images/home/hero_people.webp',
                          fit: BoxFit.fitWidth,
                          width: double.infinity,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Vertical Foreground Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 14),

                    if (isClosed) ...[
                      // Closed state: "Not accepting orders at the moment"
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_off_rounded,
                                  size: 15,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                                const SizedBox(width: 7),
                                const Text(
                                  'Not accepting orders at the moment',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // 1. "Grab a Bite" SVG with Dynamic Themed Heart
                      Center(
                        child: SizedBox(
                          height: 24,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/home/grab_a_bite_text.svg',
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                              SvgPicture.asset(
                                'assets/images/home/grab_a_bite_heart_only.svg',
                                height: 24,
                                fit: BoxFit.contain,
                                colorFilter: ColorFilter.mode(
                                  context.palette.heroHeartColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 2. "ORDER NOW" Badge directly from Figma SVG
                      Center(
                        child: SvgPicture.asset(
                          'assets/images/home/order_now.svg',
                          height: 25,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // 3. Countdown Clock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CompactDigitPair(digits: hStr),
                        const _CompactTimeColon(),
                        _CompactDigitPair(digits: mStr),
                        const _CompactTimeColon(),
                        _CompactDigitPair(digits: sStr),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Subtitle Labels: Hrs   Mins   Secs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 52,
                          child: Center(
                            child: Text(
                              'Hrs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        SizedBox(
                          width: 52,
                          child: Center(
                            child: Text(
                              'Mins',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        SizedBox(
                          width: 52,
                          child: Center(
                            child: Text(
                              'Secs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Space for bottom illustration
                    const SizedBox(height: 98),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Standalone combined HomeBlueHeader for backwards-compatibility
class HomeBlueHeader extends StatelessWidget {
  const HomeBlueHeader({
    super.key,
    required this.state,
    required this.query,
    required this.onQueryChanged,
    required this.isVegMode,
    required this.onVegChanged,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final HomeLoaded state;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final bool isVegMode;
  final ValueChanged<bool> onVegChanged;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeStickyTopBar(
          query: query,
          onQueryChanged: onQueryChanged,
          isVegMode: isVegMode,
          onVegChanged: onVegChanged,
          categories: categories,
          selectedCategory: selectedCategory,
          onCategorySelected: onCategorySelected,
          topPadding: topPadding,
          isScrolled: false,
        ),
        HomeHeroBanner(state: state),
      ],
    );
  }
}

/// White Rounded Card VEG toggle switch
class _VegToggleCard extends StatelessWidget {
  const _VegToggleCard({
    required this.value,
    required this.onChanged,
    this.isScrolled = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isScrolled;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      toggled: value,
      label: 'Vegetarian filter',
      hint: value
          ? 'Double tap to show all snacks'
          : 'Double tap to show vegetarian snacks only',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isScrolled ? const Color(0xFFF1F5F9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isScrolled
                ? Border.all(color: const Color(0xFFE2E8F0))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isScrolled ? 0.03 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'VEG',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isScrolled
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                width: 32,
                height: 13,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.5),
                  color: value
                      ? const Color(0xFF00C853)
                      : const Color(0xFFE0E0E0),
                ),
                child: AnimatedAlign(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(child: VegBadge(size: 11, isVeg: true)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Low-opacity fill, no-stroke countdown digit pair
/// Countdown digit pair where each individual digit has its own separate rounded box
class _CompactDigitPair extends StatelessWidget {
  const _CompactDigitPair({required this.digits});

  final String digits;

  @override
  Widget build(BuildContext context) {
    final d1 = digits.isNotEmpty ? digits[0] : '0';
    final d2 = digits.length > 1 ? digits[1] : '0';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IndividualDigitBox(digit: d1),
        const SizedBox(width: 4),
        _IndividualDigitBox(digit: d2),
      ],
    );
  }
}

class _IndividualDigitBox extends StatelessWidget {
  const _IndividualDigitBox({required this.digit});

  final String digit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        digit,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
          height: 1.0,
        ),
      ),
    );
  }
}

class _CompactTimeColon extends StatelessWidget {
  const _CompactTimeColon();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}
