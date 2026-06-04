import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/shell/main_shell.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.containsKey('auth_token');
      if (isLoggedIn && state.matchedLocation == '/onboarding') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const MainShell()),
    ],
  );
}
