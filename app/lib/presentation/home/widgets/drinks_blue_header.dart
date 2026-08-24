import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/app_tokens.dart';
import 'dispenser/drink_dispenser_models.dart';
import 'header_category_tab_bar.dart';

/// The top Royal Blue Header for the Drinks Tab:
/// - Starts from y=0 (top of screen)
/// - Royal Blue gradient (0xFF00BBFF -> 0xFF0078FF)
/// - Vector doodle illustration overlay (header_doodle_bg.svg)
/// - Full-width rounded search bar (no VEG toggle)
/// - Drink format filter scroller (Cold Brews, Hot Brews, Tins & Cans) with
///   solid white 2.0px baseline, trapezoidal bridge notch, white active icon,
///   and cyan inactive icons
/// - Straight flat bottom edge flush with category baseline (matching Food tab)
class DrinksBlueHeader extends StatefulWidget {
  const DrinksBlueHeader({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.selectedFormat,
    required this.onFormatChanged,
    required this.topPadding,
    this.isGridView = false,
    this.onGridViewChanged,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final DrinkFormat selectedFormat;
  final ValueChanged<DrinkFormat> onFormatChanged;
  final double topPadding;
  final bool isGridView;
  final ValueChanged<bool>? onGridViewChanged;

  @override
  State<DrinksBlueHeader> createState() => _DrinksBlueHeaderState();
}

class _DrinksBlueHeaderState extends State<DrinksBlueHeader> {
  late final TextEditingController _searchController;

  static const List<HeaderTabItem<DrinkFormat>> _tabs = [
    HeaderTabItem<DrinkFormat>(
      value: DrinkFormat.coldJuice,
      label: 'Cold Brews',
      selectedIcon: Symbols.local_drink_rounded,
      unselectedIcon: Symbols.local_drink_rounded,
    ),
    HeaderTabItem<DrinkFormat>(
      value: DrinkFormat.hotBrew,
      label: 'Hot Brews',
      selectedIcon: Symbols.coffee_rounded,
      unselectedIcon: Symbols.coffee_rounded,
    ),
    HeaderTabItem<DrinkFormat>(
      value: DrinkFormat.can,
      label: 'Tins',
      selectedIcon: Symbols.sports_bar_rounded,
      unselectedIcon: Symbols.sports_bar_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant DrinksBlueHeader oldWidget) {
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.palette.headerGradient,
        ),
      ),
      child: Stack(
        children: [
          // Background vector doodle overlay
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

              // 1. Search Bar + View Toggle (3D / Grid)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
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
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: false,
                            fillColor: Colors.transparent,
                            hintText: 'Search drinks',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9A9AA0),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF6B6B70),
                              size: 22,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      color: Color(0xFF9A9AA0),
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
                    if (widget.onGridViewChanged != null) ...[
                      const SizedBox(width: 10),
                      _ViewToggleCard(
                        isGrid: widget.isGridView,
                        onChanged: widget.onGridViewChanged!,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 2. Format Segment Tabs (using the exact same shared HeaderCategoryTabBar)
              HeaderCategoryTabBar<DrinkFormat>(
                items: _tabs,
                selectedValue: widget.selectedFormat,
                onChanged: widget.onFormatChanged,
                isScrolled: false,
              ),

              const SizedBox(height: 2),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewToggleCard extends StatelessWidget {
  const _ViewToggleCard({required this.isGrid, required this.onChanged});

  final bool isGrid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      toggled: isGrid,
      label: isGrid ? 'Grid view enabled' : 'Interactive 3D view enabled',
      hint: 'Double tap to switch views',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!isGrid);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isGrid ? 'GRID' : '3D',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                width: 38,
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isGrid
                      ? context.palette.brand
                      : const Color(0xFFE2E8F0),
                ),
                alignment: isGrid
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    isGrid ? Icons.grid_view_rounded : Icons.view_in_ar_rounded,
                    size: 10,
                    color: isGrid
                        ? context.palette.brand
                        : const Color(0xFF64748B),
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
