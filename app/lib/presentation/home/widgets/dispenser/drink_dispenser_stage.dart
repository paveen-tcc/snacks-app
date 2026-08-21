import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/app_tokens.dart';
import '../../../../core/widgets/category_scroller.dart';
import '../../../../data/local/app_database.dart';
import 'can_3d_renderer.dart';
import 'drink_carousel.dart';
import 'drink_dispenser_models.dart';
import 'hot_mug_painter.dart';
import 'shaker_cup_painter.dart';
import 'themed_dispenser_svg.dart';

/// The complete interactive 3D Drink Dispenser with balanced vertical layout,
/// authentic top machine dispensers for Cold and Hot brews, and multi-can 3D carousel.
class DrinkDispenserStage extends StatefulWidget {
  const DrinkDispenserStage({
    super.key,
    required this.allDrinks,
    required this.selectedSnackIds,
    required this.onIncrement,
    required this.onDecrement,
    this.selectedFormat,
    this.onFormatChanged,
    this.showTopTabs = true,
    this.disabled = false,
  });

  final List<LocalSnack> allDrinks;
  final List<String> selectedSnackIds;
  final ValueChanged<LocalSnack> onIncrement;
  final ValueChanged<LocalSnack> onDecrement;
  final DrinkFormat? selectedFormat;
  final ValueChanged<DrinkFormat>? onFormatChanged;
  final bool showTopTabs;
  final bool disabled;

  @override
  State<DrinkDispenserStage> createState() => _DrinkDispenserStageState();
}

class _DrinkDispenserStageState extends State<DrinkDispenserStage>
    with TickerProviderStateMixin {
  late DrinkFormat _selectedFormat;
  int _activeDrinkIndex = 0;
  bool _isFilled = false;
  bool _isPouring = false;
  bool _isSugarFree = false;
  double _tiltAngle = 0.0;

  // Animation Controllers
  late final AnimationController _liquidFillController;
  late final AnimationController _waveLoopController;
  late final AnimationController _iceFallController;
  late final AnimationController _steamLoopController;
  late final PageController _canPageController;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.selectedFormat ?? DrinkFormat.coldJuice;
    if (widget.selectedFormat == null) {
      _initFormatAndIndex();
    }

    _liquidFillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _waveLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _iceFallController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _steamLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _initFormatAndIndex();
    _activeDrinkIndex = 0;
    // Cans start with the first tin pre-selected (no pour animation needed);
    // cold/hot dispensers start empty until the user taps a flavor.
    _isFilled = _selectedFormat == DrinkFormat.can;
    _liquidFillController.value = 0.0;
    _canPageController = PageController(
      initialPage: 0,
      viewportFraction: 0.48,
    );
  }

  void _initFormatAndIndex() {
    final coldDrinks = _getDrinksForFormat(DrinkFormat.coldJuice);
    if (coldDrinks.isEmpty) {
      final hotDrinks = _getDrinksForFormat(DrinkFormat.hotBrew);
      if (hotDrinks.isNotEmpty) {
        _selectedFormat = DrinkFormat.hotBrew;
      } else {
        _selectedFormat = DrinkFormat.can;
      }
    }
  }

  List<LocalSnack> _getDrinksForFormat(DrinkFormat format) {
    return widget.allDrinks.where((d) {
      return DrinkPresentation.fromSnack(d).format == format;
    }).toList();
  }

  void _pourDrink(int index) {
    setState(() {
      _activeDrinkIndex = index;
      _isFilled = true;
      _isPouring = true;
    });

    // Cans/tins: smoothly animate the 3D can carousel to the selected page
    if (_selectedFormat == DrinkFormat.can) {
      _isPouring = false;
      if (_canPageController.positions.length == 1 && _canPageController.page?.round() != index) {
        _canPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    // Acoustic pouring sound and multi-stage fluid feedback (only for poured drinks)
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
    for (int i = 1; i <= 5; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted && _isFilled && _selectedFormat != DrinkFormat.can) {
          HapticFeedback.selectionClick();
        }
      });
    }

    _liquidFillController.reset();
    _iceFallController.reset();
    _liquidFillController.forward().then((_) {
      if (mounted) {
        setState(() => _isPouring = false);
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _iceFallController.forward();
    });
  }

  @override
  void dispose() {
    _canPageController.dispose();
    _liquidFillController.dispose();
    _waveLoopController.dispose();
    _iceFallController.dispose();
    _steamLoopController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DrinkDispenserStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFormat != null &&
        widget.selectedFormat != _selectedFormat) {
      setState(() {
        _selectedFormat = widget.selectedFormat!;
        _activeDrinkIndex = 0;
        _isFilled = _selectedFormat == DrinkFormat.can;
        _liquidFillController.value = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentFormatDrinks = _getDrinksForFormat(_selectedFormat);
    final hasDrinks = currentFormatDrinks.isNotEmpty;
    // Tins/cans are always "selected" (there's no pour to wait for); cold/hot
    // dispensers stay unselected — an empty glass — until a flavor is tapped.
    final hasSelection = _selectedFormat == DrinkFormat.can || _isFilled;
    final activeDrink = hasDrinks && hasSelection
        ? currentFormatDrinks[_activeDrinkIndex.clamp(0, currentFormatDrinks.length - 1)]
        : null;

    final presentation = activeDrink != null
        ? DrinkPresentation.fromSnack(activeDrink)
        : const DrinkPresentation(
            format: DrinkFormat.coldJuice,
            primaryColor: Colors.orange,
            secondaryColor: Colors.deepOrange,
            accentColor: Colors.amber,
            iconData: Symbols.local_drink_rounded,
            subtitle: 'Chilled Drink',
          );

    final canDrinks = _getDrinksForFormat(DrinkFormat.can);

    final stageIndex = _selectedFormat == DrinkFormat.coldJuice
        ? 0
        : (_selectedFormat == DrinkFormat.hotBrew ? 1 : 2);

    return Column(
      children: [
        // 1. Top Format Segment Bar (if enabled)
        if (widget.showTopTabs) _buildFormatSegmentTabs(palette),

        // 2. Main Interactive Dispenser Stage
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // TOP MACHINE DISPENSER ARTWORK (Juice.svg for Cold Juice, Coffee.svg for Hot Brew)
                  if (_selectedFormat != DrinkFormat.can && currentFormatDrinks.isNotEmpty)
                    ThemedDispenserSvg(
                      format: _selectedFormat,
                      height: 118,
                      isPouring: _isPouring,
                      pouringColor: presentation.primaryColor,
                    ),

                  const SizedBox(height: 8),

                  // 2. Persistent 3D Container Stage (IndexedStack ensures 3D WebGL stays warm and loaded)
                  SizedBox(
                    width: double.infinity,
                    height: _selectedFormat == DrinkFormat.can
                        ? 275
                        : (_selectedFormat == DrinkFormat.coldJuice ? 190 : 180),
                    child: Center(
                      child: IndexedStack(
                        index: stageIndex,
                        alignment: Alignment.center,
                        children: [
                          // 0: Cold Juice Shaker Cup
                          _buildColdCup(presentation, isDark),
                          // 1: Hot Brew Ceramic Mug
                          _buildHotMug(presentation, isDark),
                          // 2: 3D Multi-Can Carousel (Full original size)
                          _buildCanCarousel(canDrinks, isDark),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 3. BOTTOM COMPACT CURVED DRINK SELECTOR (Side faded, names below, and centered action buttons)
                  if (currentFormatDrinks.isNotEmpty)
                    DrinkCarousel(
                      drinks: currentFormatDrinks,
                      selectedIndex: _isFilled
                          ? _activeDrinkIndex.clamp(0, currentFormatDrinks.length - 1)
                          : -1,
                      onDrinkSelected: _pourDrink,
                      isSugarFree: _isSugarFree,
                      onSugarFreeChanged: (sugarFree) =>
                          setState(() => _isSugarFree = sugarFree),
                      selectedSnackIds: widget.selectedSnackIds,
                      onIncrement: widget.onIncrement,
                      onDecrement: widget.onDecrement,
                      format: _selectedFormat,
                      disabled: widget.disabled,
                    ),

                  const SizedBox(height: 60), // Bottom clearance for floating bar
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColdCup(DrinkPresentation presentation, bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _liquidFillController,
        _waveLoopController,
        _iceFallController,
      ]),
      builder: (context, _) {
        final fillVal = _isFilled && _selectedFormat == DrinkFormat.coldJuice
            ? _liquidFillController.value
            : 0.0;
        final waveVal = _waveLoopController.value * 2 * math.pi;
        final iceVal = _iceFallController.value;
        final streamVal = _isFilled && _selectedFormat == DrinkFormat.coldJuice
            ? (1.0 - fillVal).clamp(0.0, 1.0)
            : 0.0;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _tiltAngle = (_tiltAngle + (details.primaryDelta ?? 0) * 0.008).clamp(-0.40, 0.40);
            });
          },
          onHorizontalDragEnd: (_) {
            setState(() => _tiltAngle = 0.0);
          },
          child: CustomPaint(
            size: const Size(155, 190),
            painter: ShakerCupPainter(
              liquidColor: presentation.primaryColor,
              secondaryLiquidColor: presentation.secondaryColor,
              accentLiquidColor: presentation.accentColor,
              fillLevel: fillVal,
              wavePhase: waveVal,
              streamProgress: streamVal,
              iceProgress: iceVal,
              hasIce: true,
              hasSugar: !_isSugarFree,
              isDark: isDark,
              tiltAngle: _tiltAngle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHotMug(DrinkPresentation presentation, bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _liquidFillController,
        _steamLoopController,
      ]),
      builder: (context, _) {
        final fillVal = _isFilled && _selectedFormat == DrinkFormat.hotBrew
            ? _liquidFillController.value
            : 0.0;
        final steamVal = _steamLoopController.value;
        final streamVal = _isFilled && _selectedFormat == DrinkFormat.hotBrew
            ? (1.0 - fillVal).clamp(0.0, 1.0)
            : 0.0;

        return CustomPaint(
          size: const Size(165, 180),
          painter: HotMugPainter(
            liquidColor: presentation.primaryColor,
            secondaryLiquidColor: presentation.secondaryColor,
            accentLiquidColor: presentation.accentColor,
            fillLevel: fillVal,
            streamProgress: streamVal,
            steamPhase: steamVal,
            hasSugar: !_isSugarFree,
            isDark: isDark,
          ),
        );
      },
    );
  }

  Widget _buildCanCarousel(List<LocalSnack> drinks, bool isDark) {
    if (drinks.isEmpty) return const SizedBox.shrink();

    // Lazily built (PageView.builder): each can's WebView is only created the
    // first time it's scrolled into view, so devices never have to spin up
    // several WebGL contexts at once (that's what caused the blank/gray
    // renders). AutomaticKeepAliveClientMixin on Can3DRenderer means that once
    // a can has been built and loaded, it's kept alive and never reloaded
    // again — including when switching format tabs or bottom-nav tabs.
    return PageView.builder(
      controller: _canPageController,
      itemCount: drinks.length,
      clipBehavior: Clip.none,
      onPageChanged: (index) {
        if (_activeDrinkIndex != index) {
          setState(() {
            _activeDrinkIndex = index;
            _isFilled = true;
          });
        }
      },
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _canPageController,
          builder: (context, child) {
            // Guard with `positions.length == 1` (not just `hasClients`) before
            // touching `.position` — that getter is `positions.single`
            // internally and throws "Bad state: Too many elements" if this
            // controller is ever transiently attached to more than one
            // Scrollable (e.g. mid-rebuild while an old PageView is being torn
            // down). That thrown StateError previously aborted this sliver's
            // layout entirely, which is what made the can carousel go blank.
            double pageOffset = 0.0;
            if (_canPageController.positions.length == 1 &&
                _canPageController.position.haveDimensions) {
              pageOffset = (_canPageController.page ?? _canPageController.initialPage.toDouble()) - index;
            } else {
              pageOffset = (_activeDrinkIndex - index).toDouble();
            }

            final distance = pageOffset.abs();
            final scale = (1.0 - (distance * 0.22)).clamp(0.74, 1.0);
            final xTranslation = -pageOffset * 22.0;

            return Transform.translate(
              offset: Offset(xTranslation, 0),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: GestureDetector(
            onTap: () {
              if (_activeDrinkIndex != index) {
                _pourDrink(index);
              }
            },
            child: Center(
              child: Can3DRenderer(
                key: ValueKey('can_item_${drinks[index].id}'),
                presentation: DrinkPresentation.fromSnack(drinks[index]),
                isDark: isDark,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormatSegmentTabs(AppPalette palette) {
    final items = [
      CategoryItem(
        key: DrinkFormat.coldJuice.name,
        label: 'Cold Brews',
        icon: Symbols.local_drink_rounded,
        selectedIcon: Symbols.local_drink_rounded,
      ),
      CategoryItem(
        key: DrinkFormat.hotBrew.name,
        label: 'Hot Brews',
        icon: Symbols.coffee_rounded,
        selectedIcon: Symbols.coffee_rounded,
      ),
      CategoryItem(
        key: DrinkFormat.can.name,
        label: 'Tins & Cans',
        icon: Symbols.sports_bar_rounded,
        selectedIcon: Symbols.sports_bar_rounded,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: CategoryScroller(
        items: items,
        selectedKey: _selectedFormat.name,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        onSelected: (key) {
          final fmt = DrinkFormat.values.firstWhere((e) => e.name == key);
          if (fmt != _selectedFormat) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedFormat = fmt;
              _activeDrinkIndex = 0;
              _isFilled = false;
              _liquidFillController.value = 0.0;
            });
            if (fmt == DrinkFormat.can) {
              // Tins/cans always show the first one pre-selected (no pour animation).
              setState(() => _isFilled = true);
              // `jumpToPage` reads `.position` internally too — same
              // "Too many elements" hazard as elsewhere, so guard the same way.
              if (_canPageController.positions.length == 1) {
                _canPageController.jumpToPage(0);
              }
            }
            // Cold/hot dispensers stay empty (no flavor picked, no pour) until tapped.
          }
        },
      ),
    );
  }
}
