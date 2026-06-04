import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../design/app_theme.dart';
import '../design/app_tokens.dart';

/// A shimmering placeholder block for loading states (Swiggy/Zomato style).
///
/// The shimmer is skipped when Reduce Motion is enabled.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppRadii.rSm,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: borderRadius,
      ),
    );
    if (reduceMotion) return box;
    return box
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: palette.textTertiary.withValues(alpha: 0.18),
        );
  }
}

/// A skeleton shaped like a [FoodCard], for the snack/drink list loading state.
class FoodCardSkeleton extends StatelessWidget {
  const FoodCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 160, height: 16),
                SizedBox(height: AppSpacing.md),
                Skeleton(width: 80, height: 22, borderRadius: AppRadii.rSm),
                SizedBox(height: AppSpacing.md),
                Skeleton(width: double.infinity, height: 12),
                SizedBox(height: AppSpacing.xs),
                Skeleton(width: 140, height: 12),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            children: const [
              Skeleton(width: 96, height: 96, borderRadius: AppRadii.rLg),
              SizedBox(height: AppSpacing.sm),
              Skeleton(width: 96, height: 36, borderRadius: AppRadii.rSm),
            ],
          ),
        ],
      ),
    );
  }
}

/// A vertical list of [FoodCardSkeleton]s.
class FoodListSkeleton extends StatelessWidget {
  const FoodListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: FoodCardSkeleton(),
        ),
      ),
    );
  }
}
