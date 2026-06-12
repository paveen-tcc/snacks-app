import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/app_tokens.dart';

/// Pinned row holding an inline search field and an optional trailing toggle
/// (the veg filter on the Food tab, the sugar-free filter on the Drink tab).
/// Lives at the top of a tab and is wrapped in a HideableHeader.
class SearchVegRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                onChanged: onQueryChanged,
                textInputAction: TextInputAction.search,
                style: context.text.bodyMedium,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: palette.textTertiary,
                    size: 20,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          if (toggleLabel != null && onToggleChanged != null) ...[
            const SizedBox(width: AppSpacing.md),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  toggleLabel!,
                  style: context.text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                Switch.adaptive(
                  value: toggleValue,
                  activeTrackColor: toggleActiveColor ?? palette.veg,
                  onChanged: onToggleChanged,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
