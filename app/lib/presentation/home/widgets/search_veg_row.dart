import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/app_tokens.dart';

/// Pinned row holding an inline search field and (on the Food tab) the veg
/// toggle. Lives at the top of a tab and is wrapped in a HideableHeader.
class SearchVegRow extends StatelessWidget {
  const SearchVegRow({
    super.key,
    required this.query,
    required this.onQueryChanged,
    this.showVeg = false,
    this.vegOn = false,
    this.onVegChanged,
    this.hint = 'Search',
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final bool showVeg;
  final bool vegOn;
  final ValueChanged<bool>? onVegChanged;
  final String hint;

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
          if (showVeg) ...[
            const SizedBox(width: AppSpacing.md),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VEG',
                  style: context.text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                Switch.adaptive(
                  value: vegOn,
                  activeTrackColor: palette.veg,
                  onChanged: onVegChanged,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
