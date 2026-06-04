import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import '../design/glass.dart';

/// A liquid-glass top app bar.
///
/// Built on the standard Material [AppBar] (so SafeArea, scroll-under, titles,
/// actions and back buttons behave the platform-correct way) with a frosted
/// glass background in its `flexibleSpace`. Glass is the navigation layer per
/// Apple HIG; it degrades to a translucent-solid bar via [GlassCapability].
///
/// Use with `Scaffold(extendBodyBehindAppBar: true, ...)` so content scrolls
/// under the blur.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle,
    this.bottom,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;

  static final bool _isApple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
  static double get _toolbarHeight => _isApple ? 48 : 56;

  @override
  Size get preferredSize =>
      Size.fromHeight(_toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _toolbarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      centerTitle: centerTitle ?? _isApple,
      title: titleWidget ?? (title != null ? Text(title!) : null),
      titleTextStyle: context.text.titleLarge,
      actions: actions,
      bottom: bottom,
      flexibleSpace: const _GlassBarBackground(),
    );
  }
}

class _GlassBarBackground extends StatelessWidget {
  const _GlassBarBackground();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final glass = context.glass;
    final blur = GlassCapability.blurEnabled(context);
    final fill = palette.glassTint.withValues(
      alpha: blur ? glass.tintOpacity : glass.fallbackOpacity,
    );

    final decoration = BoxDecoration(
      color: fill,
      border: Border(
        bottom: BorderSide(color: palette.border.withValues(alpha: 0.6)),
      ),
    );

    if (!blur) {
      return DecoratedBox(decoration: decoration);
    }

    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: glass.blurSigma, sigmaY: glass.blurSigma),
          child: DecoratedBox(decoration: decoration),
        ),
      ),
    );
  }
}
