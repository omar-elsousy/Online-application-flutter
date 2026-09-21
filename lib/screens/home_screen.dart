import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import 'home/cart_tab.dart';
import 'home/catalog_tab.dart';
import 'home/orders_tab.dart';
import 'home/profile_tab.dart';
import 'home/target_tab.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  // مفاتيح الملاحة لكل تبويب لضمان بقاء الـ Bottom Bar
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = AppScope.of(context);
      if (state.isAuthenticated && !state.isBootstrapped && !state.isLoading) {
        state.loadHome();
        state.loadNotificationCount();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    if (state.isAuthenticated &&
        !state.isBootstrapped &&
        !state.isLoading &&
        state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) state.loadHome();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pages = [
      const CatalogTab(),
      const TargetTab(),
      const CartTab(),
      const OrdersTab(),
      const ProfileTab(),
    ];

    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab = !await _navigatorKeys[_tab]
            .currentState!
            .maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_tab != 0) {
            setState(() => _tab = 0);
            return false;
          }
        }
        return isFirstRouteInCurrentTab;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mansour'),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              icon: Badge.count(
                count: state.unreadNotificationsCount,
                isLabelVisible: state.unreadNotificationsCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: state.isLoading
                  ? null
                  : () async {
                      await state.loadHome();
                      await state.loadNotificationCount();
                    },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: List.generate(pages.length, (index) {
            return Navigator(
              key: _navigatorKeys[index],
              onGenerateRoute: (settings) =>
                  MaterialPageRoute(builder: (_) => pages[index]),
            );
          }),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (value) {
            state.clearError();
            if (_tab == value) {
              _navigatorKeys[value].currentState?.popUntil(
                (route) => route.isFirst,
              );
            } else {
              setState(() => _tab = value);
            }
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.track_changes_outlined),
              selectedIcon: Icon(Icons.track_changes),
              label: 'Target',
            ),
            NavigationDestination(
              icon: Badge.count(
                count: state.cartCount,
                isLabelVisible: state.cartCount > 0,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
