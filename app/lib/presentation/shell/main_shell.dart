import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

/// The app shell: countdown banner + Food/Drink/Orders/Profile tabs + glass bottom nav.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final HomeBloc _homeBloc;
  final ValueNotifier<bool> _navVisible = ValueNotifier(true);
  final Map<int, double> _tabScrollOffsets = {
    0: 0,
    1: 0,
    2: 0,
    3: 0,
    4: 0,
    5: 0,
  };
  int _index = 0;
  String _username = '';
  bool _isAdmin = false;

  List<NavDestinationData> get _destinations => [
    const NavDestinationData(
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant,
      label: 'Food',
    ),
    const NavDestinationData(
      icon: Icons.local_cafe_outlined,
      selectedIcon: Icons.local_cafe,
      label: 'Drink',
    ),
    const NavDestinationData(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Orders',
    ),
    if (_isAdmin)
      const NavDestinationData(
        icon: Icons.summarize_outlined,
        selectedIcon: Icons.summarize,
        label: 'Summary',
      ),
    if (_isAdmin)
      const NavDestinationData(
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        label: 'Budget',
      ),
    const NavDestinationData(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
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
      final maxIndex = _isAdmin ? 5 : 3;
      if (_index > maxIndex) {
        _index = 0;
      }
    });
  }

  @override
  void dispose() {
    _homeBloc.close();
    _navVisible.dispose();
    super.dispose();
  }

  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    _tabScrollOffsets[_index] = n.metrics.pixels;
    final atTop = n.metrics.pixels <= 8;
    if (atTop) {
      _navVisible.value = true;
    } else {
      if (n.direction == ScrollDirection.reverse) {
        _navVisible.value = false;
      } else if (n.direction == ScrollDirection.forward) {
        _navVisible.value = true;
      }
    }
    return false;
  }

  void _selectTab(int i) {
    if (i == _index) return;
    setState(() {
      _index = i;
      _navVisible.value = true;
    });
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
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 550),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: state is! HomeLoaded
                ? const BrandLoading(key: ValueKey('brand_loading'))
                : KeyedSubtree(
                    key: const ValueKey('main_shell_content'),
                    child: _buildShell(context),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildShell(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final palette = context.palette;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.40, 1.0],
      colors: palette.cardGlowGradient,
    );

    final isFirstTwoPages = _index <= 1;
    final overlayStyle = isFirstTwoPages
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.dark, // iOS: white text & icons
            statusBarIconBrightness: Brightness.light, // Android: white text & icons
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : (isDark
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarBrightness: Brightness.dark, // iOS: white text & icons
                statusBarIconBrightness: Brightness.light, // Android: white text & icons
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarBrightness: Brightness.light, // iOS: dark text & icons
                statusBarIconBrightness: Brightness.dark, // Android: dark text & icons
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.dark,
              ));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(gradient: gradient),
          child: Scaffold(
            backgroundColor: Colors.transparent,
          extendBody:
              true, // body scrolls under the glass nav so the blur shows
          body: Stack(
            children: [
              NotificationListener<UserScrollNotification>(
                onNotification: _onScroll,
                child: IndexedStack(
                  index: _index,
                  children: [
                    const FoodTab(),
                    const DrinkTab(),
                    SafeArea(
                      bottom: false,
                      child: OrdersTab(isActive: _index == 2),
                    ),
                    if (_isAdmin)
                      SafeArea(
                        bottom: false,
                        child: SummaryScreen(
                          isTab: true,
                          isActive: _index == 3,
                        ),
                      ),
                    if (_isAdmin)
                      SafeArea(
                        bottom: false,
                        child: BudgetScreen(isActive: _index == 4),
                      ),
                    SafeArea(
                      bottom: false,
                      child: ProfileScreen(
                        username: _username,
                        isAdmin: _isAdmin,
                        homeBloc: _homeBloc,
                      ),
                    ),
                  ],
                ),
              ),
              // Ambient bottom fade effect
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 90,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.45, 1.0],
                        colors: [
                          (isDark ? palette.background : Colors.white)
                              .withValues(alpha: 0.0),
                          (isDark ? palette.background : Colors.white)
                              .withValues(alpha: 0.65),
                          (isDark ? palette.background : Colors.white)
                              .withValues(alpha: 0.98),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
          ),
        ),
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
            key: const ValueKey('bottom-nav-motion-slot'),
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
