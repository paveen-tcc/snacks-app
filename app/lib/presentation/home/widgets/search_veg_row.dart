import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/app_tokens.dart';

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
            Semantics(
              button: true,
              toggled: widget.toggleValue,
              label: widget.toggleLabel,
              child: GestureDetector(
                onTap: () => widget.onToggleChanged!(!widget.toggleValue),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.toggleLabel!,
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        fontSize: 10,
                        color: widget.toggleValue
                            ? (widget.toggleActiveColor ?? palette.veg)
                            : palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 24,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Switch.adaptive(
                          value: widget.toggleValue,
                          activeTrackColor:
                              widget.toggleActiveColor ?? palette.veg,
                          onChanged: widget.onToggleChanged,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
