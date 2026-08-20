import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/food_assets.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../data/local/app_database.dart';
import 'drink_dispenser_models.dart';

/// A photorealistic, wall-mounted Hot Barista Coffee & Tea dispenser (Compact 30% reduced height).
/// Matches the Cold Beverage Fountain style with a clean white chassis, ambient wall drop shadow,
/// warm coffee/tea wavy liquid cards, glossy sugar cube dispenser, 0 SUGAR LED toggle,
/// and bottom mounted chrome dual espresso spout.
class HotBaristaDispenser extends StatefulWidget {
  const HotBaristaDispenser({
    super.key,
    required this.drinks,
    required this.selectedIndex,
    required this.onDrinkSelected,
    required this.isSugarFree,
    required this.onSugarFreeChanged,
  });

  final List<LocalSnack> drinks;
  final int selectedIndex;
  final ValueChanged<int> onDrinkSelected;
  final bool isSugarFree;
  final ValueChanged<bool> onSugarFreeChanged;

  @override
  State<HotBaristaDispenser> createState() => _HotBaristaDispenserState();
}

class _HotBaristaDispenserState extends State<HotBaristaDispenser> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant HotBaristaDispenser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients || widget.drinks.isEmpty) return;
    const itemWidth = 64.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final target = (widget.selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.drinks.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;
    final isDark = palette.isDark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Wall-Mounted Dispenser Chassis (Compact White Enclosure)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: isDark ? palette.surface : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: palette.brand.withValues(alpha: isDark ? 0.3 : 0.18),
                width: 1.8,
              ),
              boxShadow: [
                // Layered ambient depth shadows
                BoxShadow(
                  color: palette.brand.withValues(alpha: isDark ? 0.25 : 0.15),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Header Bar: Amber/Coffee Dot + SMART BARISTA BREWER + Scroll Hint
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 1, bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.brand,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SMART BARISTA BREWER',
                        style: TextStyle(
                          color: palette.brand,
                          fontSize: 10.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const Spacer(),
                      if (widget.drinks.length > 3)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swipe_outlined,
                              size: 11,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Swipe',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 9.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // 2. Main Row: Warm Brew Cards + Divider + Sugar Control Panel
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Horizontal Scrollable Hot Brew Cards (92px height)
                    Expanded(
                      child: SizedBox(
                        height: 92,
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          itemCount: widget.drinks.length,
                          itemBuilder: (context, index) {
                            final drink = widget.drinks[index];
                            final isSelected = index == widget.selectedIndex;
                            return _WavyHotBrewCard(
                              drink: drink,
                              index: index,
                              isSelected: isSelected,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.onDrinkSelected(index);
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    // Vertical Divider Line
                    Container(
                      width: 1.2,
                      height: 82,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: isDark
                          ? palette.divider
                          : palette.brand.withValues(alpha: 0.12),
                    ),

                    // Right Sugar Panel: SUGAR label, 3D Dispenser Button, 0 SUGAR, LED toggle
                    _HotSugarControlPanel(
                      isSugarFree: widget.isSugarFree,
                      onSugarFreeChanged: widget.onSugarFreeChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Wall Mounted Bottom Chrome Spout
          const _WallMountedHotBottomSpout(),
        ],
      ),
    );
  }
}

/// Individual Wavy Hot Coffee/Tea Card matching the Cold Dispenser structure with warm palettes.
class _WavyHotBrewCard extends StatelessWidget {
  const _WavyHotBrewCard({
    required this.drink,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final LocalSnack drink;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  _HotDrinkStyle _resolveStyle(String name, int idx) {
    final presentation = DrinkPresentation.fromName(name);
    return _HotDrinkStyle(
      title: name,
      gradient: [presentation.primaryColor, presentation.secondaryColor],
      icon: presentation.iconData,
      localAsset: resolveLocalFoodAsset(name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle(drink.name, index);
    final palette = context.palette;
    final isDark = palette.isDark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: isDark ? palette.surfaceElevated : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected
                ? palette.brand
                : (isDark
                    ? palette.border
                    : palette.brand.withValues(alpha: 0.16)),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.brand.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 3,
                    offset: const Offset(0, 1.5),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Column(
            children: [
              // Top Liquid Wave Fill with Center Drink PNG Image or Icon
              Expanded(
                flex: 11,
                child: Stack(
                  children: [
                    // Liquid Wave Background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _HotLiquidWavePainter(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: style.gradient,
                          ),
                        ),
                      ),
                    ),

                    // Organic Micro-Bubbles / Steam particles
                    Positioned(
                      top: 8,
                      left: 7,
                      child: Container(
                        width: 2.8,
                        height: 2.8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 8,
                      child: Container(
                        width: 2.2,
                        height: 2.2,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.40),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // Centered Drink PNG Image or Vector Icon
                    Center(
                      child: style.localAsset != null
                          ? Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Image.asset(
                                style.localAsset!,
                                width: 34,
                                height: 34,
                                fit: BoxFit.contain,
                                cacheWidth: 100,
                                errorBuilder: (c, e, s) => Icon(
                                  style.icon,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                style.icon,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // Bottom Name & Dispense Push Bar
              Expanded(
                flex: 9,
                child: Container(
                  color: isDark ? palette.surface : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Drink Name in Accent
                      Expanded(
                        child: Center(
                          child: Text(
                            drink.name.isNotEmpty ? drink.name : style.title,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? palette.brand
                                  : (isDark
                                      ? palette.textPrimary
                                      : const Color(0xFF1E293B)),
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),

                      // Dispense Push Bar Indicator Pill
                      Container(
                        width: 16,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.brand
                              : (isDark
                                  ? palette.surfaceMuted
                                  : palette.brand.withValues(alpha: 0.18)),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ],
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

class _HotDrinkStyle {
  _HotDrinkStyle({
    required this.title,
    required this.gradient,
    required this.icon,
    this.localAsset,
  });

  final String title;
  final List<Color> gradient;
  final IconData icon;
  final String? localAsset;
}

/// Custom painter rendering the smooth wavy liquid boundary.
class _HotLiquidWavePainter extends CustomPainter {
  _HotLiquidWavePainter({required this.gradient});

  final Gradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);

    final path = Path();
    path.moveTo(0, 6);
    path.quadraticBezierTo(
      size.width * 0.28,
      13,
      size.width * 0.52,
      7,
    );
    path.quadraticBezierTo(
      size.width * 0.78,
      2,
      size.width,
      9,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HotLiquidWavePainter oldDelegate) => false;
}

/// Right Sugar Panel for Hot Brewer.
class _HotSugarControlPanel extends StatelessWidget {
  const _HotSugarControlPanel({
    required this.isSugarFree,
    required this.onSugarFreeChanged,
  });

  final bool isSugarFree;
  final ValueChanged<bool> onSugarFreeChanged;

  @override
  Widget build(BuildContext context) {
    final hasSugar = !isSugarFree;
    final palette = context.palette;

    return SizedBox(
      width: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // "SUGAR" Header Label
          Text(
            'SUGAR',
            style: TextStyle(
              color: palette.brand,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 5),

          // Clean, tactile switch toggle
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSugarFreeChanged(!isSugarFree);
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 22,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: hasSugar
                    ? palette.brand
                    : const Color(0xFFCBD5E1),
                boxShadow: hasSugar
                    ? [
                        BoxShadow(
                          color: palette.brand.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: hasSugar ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // Status label under switch
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: hasSugar ? palette.brand : const Color(0xFF64748B),
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
            child: Text(hasSugar ? 'REGULAR' : '0 SUGAR'),
          ),
        ],
      ),
    );
  }
}

/// Wall-Mounted Bottom Chrome Dual Spout for Barista Brewer.
class _WallMountedHotBottomSpout extends StatelessWidget {
  const _WallMountedHotBottomSpout();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mounting Bracket Tab
        Container(
          width: 40,
          height: 6,
          decoration: BoxDecoration(
            color: palette.brand.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: palette.brand.withValues(alpha: 0.2),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
        ),

        // Chrome Dual Nozzle Spout
        Container(
          width: 20,
          height: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.brand.withValues(alpha: 0.12),
                palette.brand.withValues(alpha: 0.30),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(6),
            ),
            border: Border.all(
              color: palette.brand.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.brand.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 4,
                height: 2.5,
                margin: const EdgeInsets.only(bottom: 1.5),
                decoration: BoxDecoration(
                  color: palette.brandPressed,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
              Container(
                width: 4,
                height: 2.5,
                margin: const EdgeInsets.only(bottom: 1.5),
                decoration: BoxDecoration(
                  color: palette.brandPressed,
                  borderRadius: BorderRadius.circular(1.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
