import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/notion_theme.dart';
import '../../core/di/locator.dart';
import '../../core/auth/msal_service.dart';
import '../../core/widgets/illustrations.dart';
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
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      const WelcomeIllustration(width: 280),
                      const SizedBox(height: 32),
                      Text(
                        'Welcome to Snacks',
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with your organization account to continue.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: NotionTheme.secondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          children: [
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: NotionTheme.redAccent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: NotionTheme.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _signInWithMicrosoft,
                                icon: _isLoading
                                    ? const SizedBox.shrink()
                                    : const Icon(Icons.business, size: 20),
                                label: _isLoading
                                    ? const FoodLoaderInline(size: 18)
                                    : const Text('Sign in with Microsoft'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
