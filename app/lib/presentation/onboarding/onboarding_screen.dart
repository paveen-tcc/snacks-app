import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/di/locator.dart';
import '../../core/auth/msal_service.dart';
import '../../core/notifications/push_service.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/app_buttons.dart';
import '../../data/repositories/auth_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithMicrosoft() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final msalService = locator<MsalService>();
      final idToken = await msalService.signIn();

      final authRepo = locator<AuthRepository>();
      await authRepo.loginWithMicrosoft(idToken);

      // Register for order-reminder push (prompts for permission). Fire and
      // forget so landing on home isn't blocked by the permission dialog.
      locator<PushService>().registerForCurrentUser();

      if (mounted) context.go('/');
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: Container(
        // Warm brand gradient backdrop for an appetizing, vibrant welcome.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.brand.withValues(alpha: palette.isDark ? 0.18 : 0.10),
              palette.background,
              palette.background,
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x3,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSpacing.xxl),
                        AppLogo(
                          size: 128,
                          borderRadius: AppRadii.rXl,
                          shadows: context.shadows.lg,
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        Text(
                          'Welcome to TCC Pantry',
                          style: context.text.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Sign in with your organization account to continue.',
                          style: context.text.bodyLarge?.copyWith(
                            color: palette.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            children: [
                              if (_errorMessage != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: palette.danger.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: AppRadii.rMd,
                                    border: Border.all(
                                      color: palette.danger.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: context.text.bodySmall?.copyWith(
                                      color: palette.danger,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              PrimaryButton(
                                label: 'Sign in with Microsoft',
                                icon: Icons.business_rounded,
                                loading: _isLoading,
                                onPressed: _signInWithMicrosoft,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
