import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/app_tokens.dart';
import '../../core/di/locator.dart';
import '../../core/notifications/push_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../admin/budget_screen.dart';
import '../admin/summary_screen.dart';
import '../home/bloc/home_bloc.dart';
import '../home/cart.dart';
import '../home/drink_tab.dart';
import '../home/food_tab.dart';
import '../home/home_helpers.dart';
import '../orders/orders_tab.dart';
import '../profile/profile_screen.dart';
import 'brand_loading.dart';
import 'glass_bottom_nav.dart';

/// The app shell: greeting bar (profile top-left, only visible at the top of the
/// list) + Food/Drink/Orders tabs + glass bottom nav. The greeting hides on any
/// scroll; the bottom nav hides on scroll-down and returns on scroll-up; the
/// per-tab search + veg row is always visible.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final HomeBloc _homeBloc;
  final ValueNotifier<bool> _navVisible = ValueNotifier(true);
  final ValueNotifier<bool> _greetingVisible = ValueNotifier(true);
  int _index = 0;
  String _username = '';
  bool _isAdmin = false;

  List<NavDestinationData> get _destinations => [
    const NavDestinationData(
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant_rounded,
      label: 'Food',
    ),
    const NavDestinationData(
      icon: Icons.local_cafe_outlined,
      selectedIcon: Icons.local_cafe_rounded,
      label: 'Drink',
    ),
    const NavDestinationData(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      label: 'Orders',
    ),
    if (_isAdmin)
      const NavDestinationData(
        icon: Icons.summarize_outlined,
        selectedIcon: Icons.summarize_rounded,
        label: 'Summary',
      ),
    if (_isAdmin)
      const NavDestinationData(
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet_rounded,
        label: 'Budget',
      ),
  ];

  @override
  void initState() {
    super.initState();
    _homeBloc = HomeBloc();
    _refreshViewer();
  }

  Future<void> _refreshViewer() async {
    try {
      await locator<AuthRepository>().refreshSession();
    } catch (_) {
      /* keep cached */
    }
    // Ensure this device's FCM token is registered for order reminders.
    locator<PushService>().registerForCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username = prefs.getString('username') ?? '';
      _isAdmin = prefs.getBool('is_admin') ?? false;
      final maxIndex = _isAdmin ? 4 : 2;
      if (_index > maxIndex) {
        _index = 0;
      }
    });
  }

  @override
  void dispose() {
    _homeBloc.close();
    _navVisible.dispose();
    _greetingVisible.dispose();
    super.dispose();
  }

  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final atTop = n.metrics.pixels <= 8;
    if (atTop) {
      _navVisible.value = true;
      _greetingVisible.value = true;
    } else if (n.direction == ScrollDirection.reverse) {
      _navVisible.value = false;
      _greetingVisible.value = false;
    } else if (n.direction == ScrollDirection.forward) {
      _navVisible.value = true;
      _greetingVisible.value = true;
    }
    return false;
  }

  void _selectTab(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _navVisible.value = true;
    _greetingVisible.value = true;
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          username: _username,
          isAdmin: _isAdmin,
          homeBloc: _homeBloc,
        ),
      ),
    );
    if (mounted) _refreshViewer();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeBloc,
      child: BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (prev, curr) =>
            curr is HomeLoaded &&
            curr.orderError != null &&
            (prev is! HomeLoaded || prev.errorNonce != curr.errorNonce),
        listener: (context, state) {
          final message = (state as HomeLoaded).orderError;
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          if (state is HomeError) {
            return const Scaffold(
              body: Center(child: Text('Something went wrong')),
            );
          }
          if (state is! HomeLoaded) return const BrandLoading();
          return _buildShell(context);
        },
      ),
    );
  }

  Widget _buildShell(BuildContext context) {
    return Scaffold(
      extendBody: true, // body scrolls under the glass nav so the blur shows
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Hideable(
              visible: _greetingVisible,
              child: _GreetingBar(
                username: _username,
                onProfileTap: _openProfile,
              ),
            ),
            Expanded(
              child: NotificationListener<UserScrollNotification>(
                onNotification: _onScroll,
                child: IndexedStack(
                  index: _index,
                  children: [
                    const FoodTab(),
                    const DrinkTab(),
                    OrdersTab(isActive: _index == 2),
                    if (_isAdmin)
                      SummaryScreen(isTab: true, isActive: _index == 3),
                    if (_isAdmin) BudgetScreen(isActive: _index == 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomChrome(
        navVisible: _navVisible,
        showCart: _index == 0 || _index == 1,
        homeBloc: _homeBloc,
        nav: GlassBottomNav(
          currentIndex: _index,
          onTap: _selectTab,
          destinations: _destinations,
        ),
      ),
    );
  }
}

/// Slides and collapses [child] vertically when [visible] is false.
class _Hideable extends StatelessWidget {
  const _Hideable({required this.visible, required this.child});
  final ValueListenable<bool> visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion ? Duration.zero : AppMotion.slow;
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, isVisible, child) => AnimatedSize(
        duration: duration,
        curve: AppMotion.emphasized,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: AppMotion.emphasized,
          switchOutCurve: AppMotion.emphasized,
          transitionBuilder: (switchChild, animation) {
            final position = Tween<Offset>(
              begin: const Offset(0, -0.28),
              end: Offset.zero,
            ).animate(animation);
            return ClipRect(
              child: SlideTransition(
                position: position,
                child: FadeTransition(opacity: animation, child: switchChild),
              ),
            );
          },
          child: isVisible
              ? KeyedSubtree(key: const ValueKey('visible'), child: child!)
              : const SizedBox(
                  key: ValueKey('hidden'),
                  width: double.infinity,
                  height: 0,
                ),
        ),
      ),
      child: child,
    );
  }
}

class _GreetingBar extends StatelessWidget {
  const _GreetingBar({required this.username, required this.onProfileTap});

  final String username;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '🙂';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${username.isNotEmpty ? username : 'there'}',
                  style: context.text.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Semantics(
            button: true,
            label: 'Profile and settings',
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: AppRadii.rPill,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: palette.brand.withValues(alpha: 0.14),
                child: Text(
                  initial,
                  style: context.text.titleMedium?.copyWith(
                    color: palette.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky cart bar (always visible when applicable) + the hideable glass nav.
class _BottomChrome extends StatelessWidget {
  const _BottomChrome({
    required this.navVisible,
    required this.showCart,
    required this.nav,
    required this.homeBloc,
  });

  final ValueListenable<bool> navVisible;
  final bool showCart;
  final Widget nav;
  final HomeBloc homeBloc;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final duration = reduceMotion ? Duration.zero : AppMotion.slow;

    return ValueListenableBuilder<bool>(
      valueListenable: navVisible,
      builder: (context, visible, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCart)
            BlocBuilder<HomeBloc, HomeState>(
              bloc: homeBloc,
              builder: (context, state) {
                if (state is! HomeLoaded) return const SizedBox.shrink();
                final itemCount = state.selectedSnackIds.length;
                final orderPlaced = isOrderPlaced(state);
                final hasChanges = hasOrderChanges(state);
                final closeTime = formatOrderWindowCloseTime(state);
                if (state.isShutdown ||
                    isOrderingClosed(state) ||
                    (itemCount == 0 && !hasChanges && !orderPlaced)) {
                  return const SizedBox.shrink();
                }
                return AnimatedPadding(
                  duration: duration,
                  curve: AppMotion.emphasized,
                  padding: EdgeInsets.only(bottom: visible ? 0 : bottomInset),
                  child: CartBar(
                    itemCount: itemCount,
                    orderPlaced: orderPlaced,
                    hasChanges: hasChanges,
                    editUntilLabel: closeTime,
                    onTap: () => showCartSheet(context, homeBloc),
                  ),
                );
              },
            ),
          AnimatedSize(
            duration: duration,
            curve: AppMotion.emphasized,
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: duration,
              switchInCurve: AppMotion.emphasized,
              switchOutCurve: AppMotion.emphasized,
              transitionBuilder: (switchChild, animation) {
                final position = Tween<Offset>(
                  begin: const Offset(0, 0.42),
                  end: Offset.zero,
                ).animate(animation);
                return ClipRect(
                  child: SlideTransition(
                    position: position,
                    child: FadeTransition(
                      opacity: animation,
                      child: switchChild,
                    ),
                  ),
                );
              },
              child: visible
                  ? KeyedSubtree(key: const ValueKey('nav-visible'), child: nav)
                  : const SizedBox(
                      key: ValueKey('nav-hidden'),
                      width: double.infinity,
                      height: 0,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
