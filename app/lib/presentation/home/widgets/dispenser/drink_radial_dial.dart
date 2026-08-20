import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../data/local/app_database.dart';
import 'drink_dispenser_models.dart';

/// A circular curved bottom dial for selecting drinks by clicking.
/// For cans/tins, renders actual drink brand image logos (Coke, Diet Coke, Red Bull, Monster).
/// All selected items share the same unified brand selection color styling.
class DrinkRadialDial extends StatefulWidget {
  const DrinkRadialDial({
    super.key,
    required this.drinks,
    required this.selectedIndex,
    required this.onDrinkTapped,
  });

  final List<LocalSnack> drinks;
  final int selectedIndex;
  final ValueChanged<int> onDrinkTapped;

  @override
  State<DrinkRadialDial> createState() => _DrinkRadialDialState();
}

class _DrinkRadialDialState extends State<DrinkRadialDial> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initial = widget.selectedIndex.clamp(0, widget.drinks.isEmpty ? 0 : widget.drinks.length - 1);
    _pageController = PageController(
      initialPage: initial,
      viewportFraction: 0.28,
    );
  }

  @override
  void didUpdateWidget(covariant DrinkRadialDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        _pageController.hasClients &&
        _pageController.page?.round() != widget.selectedIndex) {
      _pageController.animateToPage(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (widget.drinks.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular Arc Guide Track in Background
          CustomPaint(
            size: const Size(double.infinity, 92),
            painter: _ArcTrackPainter(color: palette.border.withValues(alpha: 0.35)),
          ),

          // Horizontal Carousel Wheel
          PageView.builder(
            controller: _pageController,
            itemCount: widget.drinks.length,
            onPageChanged: (index) {
              if (widget.selectedIndex != index) {
                widget.onDrinkTapped(index);
              }
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double pageOffset = 0.0;
                  if (_pageController.position.haveDimensions) {
                    pageOffset = (_pageController.page ?? _pageController.initialPage.toDouble()) - index;
                  } else {
                    pageOffset = (widget.selectedIndex - index).toDouble();
                  }

                  final distance = pageOffset.abs();
                  final scale = (1.0 - (distance * 0.24)).clamp(0.68, 1.14);
                  final opacity = (1.0 - (distance * 0.40)).clamp(0.45, 1.0);
                  final yOffset = math.sin(distance * 0.65) * 8.0;

                  final drink = widget.drinks[index];
                  final presentation = DrinkPresentation.fromSnack(drink);
                  final isSelected = index == widget.selectedIndex;

                  return Transform.translate(
                    offset: Offset(0, yOffset),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                            );
                            widget.onDrinkTapped(index);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Brand Badge / Bubble with Clean Highlighted Circle Stroke (No fill color)
                              Container(
                                width: 50,
                                height: 50,
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: isSelected ? palette.brand : palette.border.withValues(alpha: 0.6),
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: _buildBrandBadgeContent(drink, presentation, isSelected, palette),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                drink.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: context.text.labelSmall?.copyWith(
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? palette.textPrimary : palette.textSecondary,
                                  fontSize: isSelected ? 11.5 : 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrandBadgeContent(
    LocalSnack drink,
    DrinkPresentation presentation,
    bool isSelected,
    AppPalette palette,
  ) {
    // 1. If an authentic brand logo image asset exists, render it cropped inside the bubble
    if (presentation.logoAssetPath != null) {
      return ClipOval(
        child: Image.asset(
          presentation.logoAssetPath!,
          fit: BoxFit.cover,
          width: 44,
          height: 44,
          cacheWidth: 140,
          errorBuilder: (context, error, stackTrace) => Icon(
            presentation.iconData,
            size: 24,
            color: isSelected ? palette.brand : palette.textSecondary,
          ),
        ),
      );
    }

    final name = drink.name.toLowerCase().trim();

    // 2. Styled text badges for other cans without specific images (Sprite, Thums Up)
    if (presentation.format == DrinkFormat.can) {
      if (name.contains('sprite') || name.contains('7up')) {
        return Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF008B47),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Sprite',
            style: TextStyle(
              color: Color(0xFFFFEB3B),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
      if (name.contains('thums')) {
        return Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0D47A1),
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.thumb_up_alt_rounded, size: 10, color: Colors.white),
              SizedBox(width: 1),
              Text(
                'Up',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }
    }

    // 3. Default Hot Brews & Cold Brews Icon
    return Center(
      child: Icon(
        presentation.iconData,
        size: 24,
        color: isSelected ? palette.brand : palette.textSecondary,
      ),
    );
  }
}

class _ArcTrackPainter extends CustomPainter {
  const _ArcTrackPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.86,
        size.width,
        size.height * 0.72,
      );

    canvas.drawPath(path, trackPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcTrackPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
