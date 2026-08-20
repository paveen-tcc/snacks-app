import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'app_tokens.dart';

/// Decides whether real Gaussian-blur glass should be used, or the cheaper
/// translucent-solid fallback.
///
/// Per Apple HIG + Flutter perf guidance, blur ([BackdropFilter]/`saveLayer`) is
/// the main jank source on old GPUs, so we degrade gracefully when:
///  - the OS reports Reduce Transparency / Increase Contrast,
///  - running on web (BackdropFilter is heavy/inconsistent there), or
///  - the app forces it off (e.g. a detected low-end device).
class GlassCapability {
  GlassCapability._();

  /// Escape hatch for app wiring to force the solid fallback globally.
  static bool forceDisableBlur = false;

  static bool blurEnabled(BuildContext context) {
    if (forceDisableBlur) return false;
    if (kIsWeb) return false;
    final mq = MediaQuery.maybeOf(context);
    if (mq != null && mq.highContrast) return false;
    return true;
  }
}

/// A frosted "liquid glass" surface for the navigation layer (app bars, the
/// view-cart bar, sheet headers) — never for scrolling content cards.
///
/// Renders a [BackdropFilter] blur + translucent tint + hairline rim + subtle
/// top highlight, wrapped in a [RepaintBoundary] so scroll repaints don't
/// re-run the blur. When blur is unavailable it falls back to a high-opacity
/// solid tint that stays legible.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = AppRadii.rLg,
    this.padding,
    this.tint,
    this.blurSigma,
    this.showBorder = true,
    this.showHighlight = true,
    this.shadows,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Override the tint color (defaults to the palette's glass tint).
  final Color? tint;

  /// Override the blur sigma (defaults to the theme's glass style).
  final double? blurSigma;

  final bool showBorder;
  final bool showHighlight;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final glass = context.glass;
    final blur = GlassCapability.blurEnabled(context);

    final base = tint ?? palette.glassTint;
    final fill = base.withValues(
      alpha: blur ? glass.tintOpacity : glass.fallbackOpacity,
    );

    final decoration = BoxDecoration(
      color: fill,
      borderRadius: borderRadius,
      border: showBorder
          ? Border.all(
              color: Colors.white.withValues(alpha: glass.borderOpacity),
              width: 1,
            )
          : null,
      gradient: showHighlight
          ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: glass.highlightOpacity),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0, 0.55],
            )
          : null,
    );

    Widget content = DecoratedBox(
      decoration: decoration,
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (!blur) {
      // Solid fallback — add a soft shadow so it still reads as a floating bar.
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: shadows ?? context.shadows.sm,
        ),
        child: ClipRRect(borderRadius: borderRadius, child: content),
      );
    }

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma ?? glass.blurSigma,
            sigmaY: blurSigma ?? glass.blurSigma,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Shows the app's modal bottom sheet (cart, forms, dialogs).
///
/// Bottom sheets use an opaque themed surface so dense content and form fields
/// keep reliable contrast over every screen background. Navigation chrome can
/// still use [GlassSurface], but modal content should not inherit page colours.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
}) {
  const radius = BorderRadius.vertical(top: Radius.circular(AppRadii.xl));
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.58 : 0.38),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.92,
    ),
    builder: (context) {
      final palette = context.palette;
      return Material(
        key: const ValueKey('app_bottom_sheet_surface'),
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            _DragHandle(),
            const SizedBox(height: AppSpacing.xs),
            Flexible(child: builder(context)),
          ],
        ),
      );
    },
  );
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: context.palette.textTertiary.withValues(alpha: 0.5),
        borderRadius: AppRadii.rPill,
      ),
    );
  }
}
