import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/widgets/food_card.dart' show VegBadge;

/// Pinned row holding an inline search field and an optional trailing toggle
/// (the veg filter on the Food tab, the sugar-free filter on the Drink tab).
/// Lives at the top of a tab and is wrapped in a HideableHeader.
class SearchVegRow extends StatefulWidget {
  const SearchVegRow({
    super.key,
    required this.query,
    required this.onQueryChanged,
    this.hint = 'Search',
    this.toggleLabel,
    this.toggleValue = false,
    this.onToggleChanged,
    this.toggleActiveColor,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final String hint;

  /// When [toggleLabel] and [onToggleChanged] are both provided, a labelled
  /// switch is shown to the right of the search field.
  final String? toggleLabel;
  final bool toggleValue;
  final ValueChanged<bool>? onToggleChanged;
  final Color? toggleActiveColor;

  @override
  State<SearchVegRow> createState() => _SearchVegRowState();
}

class _SearchVegRowState extends State<SearchVegRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant SearchVegRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final showToggle = widget.toggleLabel != null && widget.onToggleChanged != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _controller,
                onChanged: (val) {
                  widget.onQueryChanged(val);
                  setState(() {});
                },
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                textInputAction: TextInputAction.search,
                style: context.text.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: palette.textTertiary,
                    size: 20,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: palette.textTertiary,
                            size: 18,
                          ),
                          splashRadius: 16,
                          onPressed: () {
                            _controller.clear();
                            widget.onQueryChanged('');
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          if (showToggle) ...[
            const SizedBox(width: AppSpacing.md),
            VegToggleSwitch(
              value: widget.toggleValue,
              onChanged: widget.onToggleChanged!,
              label: widget.toggleLabel,
              activeColor: widget.toggleActiveColor,
            ),
          ],
        ],
      ),
    );
  }
}

/// A custom, premium toggle switch designed in the style of official Indian
/// food apps (Swiggy / Zomato), featuring the iconic Veg badge on the sliding thumb knob.
class VegToggleSwitch extends StatelessWidget {
  const VegToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final vegColor = activeColor ?? palette.veg;
    final isDark = palette.isDark;

    return Semantics(
      button: true,
      toggled: value,
      label: label ?? (value ? 'Vegetarian only' : 'All snacks'),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label != null) ...[
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: (context.text.labelSmall ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  fontSize: 10,
                  color: value ? vegColor : palette.textSecondary,
                ),
                child: Text(label!),
              ),
              const SizedBox(height: 3),
            ],
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: value
                    ? vegColor.withValues(alpha: 0.12)
                    : palette.surfaceMuted,
                border: Border.all(
                  color: value
                      ? vegColor
                      : palette.textTertiary.withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isDark
                        ? palette.surfaceElevated
                        : Colors.white,
                    borderRadius: BorderRadius.circular(3.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: VegBadge(
                    isVeg: true,
                    size: 13,
                    color: value
                        ? vegColor
                        : palette.textTertiary.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
