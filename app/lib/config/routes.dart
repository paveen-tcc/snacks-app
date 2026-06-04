import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/history/history_screen.dart';
import '../presentation/admin/admin_dashboard_screen.dart';

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
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}
