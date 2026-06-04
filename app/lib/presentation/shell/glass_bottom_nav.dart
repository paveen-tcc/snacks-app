import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/design/glass.dart';

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

/// A frosted "liquid glass" bottom navigation bar (Apple HIG nav layer).
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavDestinationData> destinations;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < destinations.length; i++)
              _NavItem(
                data: destinations[i],
                selected: i == currentIndex,
                onTap: () {
                  if (i != currentIndex) HapticFeedback.selectionClick();
                  onTap(i);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final NavDestinationData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final color = selected ? palette.brand : palette.textSecondary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: data.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.rPill,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : AppMotion.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? palette.brand.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: AppRadii.rPill,
                  ),
                  child: Icon(
                    selected ? data.selectedIcon : data.icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: context.text.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
