import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/api_item.dart';
import 'home/cart_tab.dart';
import 'home/catalog_tab.dart';
import 'home/orders_tab.dart';
import 'home/profile_tab.dart';
import 'home/target_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  // مفاتيح الـ Navigator لكل تبويب لضمان استقلال التنقل
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    if (state.isAuthenticated && !state.isBootstrapped && !state.isLoading && state.error == null) {
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
        final isFirstRouteInCurrentTab = !await _navigatorKeys[_tab].currentState!.maybePop();
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
              tooltip: 'Refresh',
              onPressed: state.isLoading ? null : state.loadHome,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: List.generate(pages.length, (index) {
            return Navigator(
              key: _navigatorKeys[index],
              onGenerateRoute: (routeSettings) {
                return MaterialPageRoute(builder: (_) => pages[index]);
              },
            );
          }),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (value) {
            state.clearError(); // مسح أي رسالة عالقة عند التنقل بين الـ Tabs
            setState(() => _tab = value);
          },
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            const NavigationDestination(icon: Icon(Icons.track_changes_outlined), selectedIcon: Icon(Icons.track_changes), label: 'Target'),
            NavigationDestination(
              icon: Badge.count(
                count: state.cartCount,
                isLabelVisible: state.cartCount > 0,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
            const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
