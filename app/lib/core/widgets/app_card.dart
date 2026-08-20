import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import '../design/app_tokens.dart';
import 'app_buttons.dart' show PressableScale;

/// A soft, rounded surface card with a subtle shadow (content layer — no glass).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.borderRadius = AppRadii.rLg,
    this.border,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius borderRadius;
  final BoxBorder? border;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? palette.surface,
        borderRadius: borderRadius,
        border: border ?? Border.all(color: palette.border),
        boxShadow: elevated ? context.shadows.sm : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return PressableScale(
      onTap: onTap,
      borderRadius: borderRadius,
      child: card,
    );
  }
}

/// A section title with optional subtitle and trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: context.text.bodySmall?.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

enum StatusTone { info, success, warning, danger, neutral }

/// An inline status banner (replaces the old status / cutoff / shutdown
/// containers). Tinted by [tone] with a leading icon.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.tone = StatusTone.info,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final StatusTone tone;
  final Widget? trailing;

  IconData _defaultIcon() {
    switch (tone) {
      case StatusTone.info:
        return Icons.info_outline_rounded;
      case StatusTone.success:
        return Icons.check_circle_outline_rounded;
      case StatusTone.warning:
        return Icons.warning_amber_rounded;
      case StatusTone.danger:
        return Icons.error_outline_rounded;
      case StatusTone.neutral:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = palette.isDark;
    final isSingleLine = subtitle == null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: isSingleLine ? 10 : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1F27), const Color(0xFF15161C)]
              : [const Color(0xFFFFF7F2), const Color(0xFFFFFFFF)],
        ),
        borderRadius: AppRadii.rMd,
        border: Border.all(
          color: isDark ? palette.border : const Color(0xFFEDE8E3),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isSingleLine ? 32 : 38,
            height: isSingleLine ? 32 : 38,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF4EDE7),
              borderRadius: AppRadii.rSm,
            ),
            child: Icon(
              icon ?? _defaultIcon(),
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              size: isSingleLine ? 18 : 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: (isSingleLine
                          ? context.text.bodyMedium
                          : context.text.titleSmall)
                      ?.copyWith(
                    color: context.palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: context.text.bodySmall?.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
