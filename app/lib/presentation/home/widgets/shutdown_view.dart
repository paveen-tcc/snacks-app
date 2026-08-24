import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/illustrations.dart';
import '../bloc/home_bloc.dart';

/// Shared explanatory state used by Food and Drink when ordering is disabled
/// for the entire day.
class ShutdownView extends StatelessWidget {
  const ShutdownView({super.key, required this.state});

  final HomeLoaded state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x3,
          AppSpacing.xxl,
          AppSpacing.x3,
          120,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ShutdownIllustration(width: 220),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                state.shutdownType == 'holiday'
                    ? 'Happy Holiday!'
                    : 'No Orders Today',
                style: context.text.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.shutdownReason ?? 'The kitchen is taking a break today',
                style: context.text.bodyMedium?.copyWith(
                  color: context.palette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              StatusBanner(
                tone: StatusTone.info,
                icon: state.shutdownType == 'holiday'
                    ? Icons.celebration_rounded
                    : Icons.info_outline_rounded,
                title: 'Orders will resume on the next working day',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
