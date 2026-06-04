import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';

/// Branded loading screen shown while the home data loads — an animated
/// "TCC Pantry" reveal. Animations are skipped under Reduce Motion.
class BrandLoading extends StatelessWidget {
  const BrandLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget mark = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.brand, palette.brandPressed],
        ),
        borderRadius: AppRadii.rXl,
        boxShadow: context.shadows.lg,
      ),
      alignment: Alignment.center,
      child: const Text('🍿', style: TextStyle(fontSize: 48)),
    );

    Widget title = Text(
      'TCC Pantry',
      style: context.text.displayMedium?.copyWith(color: palette.textPrimary),
    );

    Widget tagline = Text(
      'Snacks, sorted.',
      style: context.text.bodyMedium?.copyWith(color: palette.textSecondary),
    );

    if (!reduceMotion) {
      mark = mark
          .animate()
          .scale(
            duration: 450.ms,
            curve: Curves.easeOutBack,
            begin: const Offset(0.6, 0.6),
            end: const Offset(1, 1),
          )
          .fadeIn(duration: 350.ms);
      title = title
          .animate()
          .fadeIn(delay: 220.ms, duration: 400.ms)
          .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic);
      tagline = tagline.animate().fadeIn(delay: 420.ms, duration: 400.ms);
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            const SizedBox(height: AppSpacing.xxl),
            title,
            const SizedBox(height: AppSpacing.sm),
            tagline,
          ],
        ),
      ),
    );
  }
}
