import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'customers_screen.dart';
import 'export_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _productsKey = GlobalKey<ProductsScreenState>();
  final _salesKey = GlobalKey<SalesScreenState>();
  final _customersKey = GlobalKey<CustomersScreenState>();

  void _handleQuickAction(String action) {
    switch (action) {
      case 'new_sale':
        setState(() => _index = 2);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _salesKey.currentState?.openNewSaleSheet();
        });
        break;
      case 'add_product':
        setState(() => _index = 1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _productsKey.currentState?.openAddSheet();
        });
        break;
      case 'add_customer':
        setState(() => _index = 3);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _customersKey.currentState?.openAddSheet();
        });
        break;
      case 'export_pdf':
        setState(() => _index = 4);
        break;
    }
  }

  final _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Accueil',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2_rounded),
      label: 'Produits',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long_rounded),
      label: 'Ventes',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_alt_outlined),
      selectedIcon: Icon(Icons.people_alt_rounded),
      label: 'Clients',
    ),
    NavigationDestination(
      icon: Icon(Icons.picture_as_pdf_outlined),
      selectedIcon: Icon(Icons.picture_as_pdf_rounded),
      label: 'Export',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        key: _dashboardKey,
        onProfileTap: () => setState(() => _index = 5),
        onQuickAction: _handleQuickAction,
      ),
      ProductsScreen(
        key: _productsKey,
        onProfileTap: () => setState(() => _index = 5),
      ),
      SalesScreen(
        key: _salesKey,
        onProfileTap: () => setState(() => _index = 5),
      ),
      CustomersScreen(
        key: _customersKey,
        onProfileTap: () => setState(() => _index = 5),
      ),
      ExportScreen(onProfileTap: () => setState(() => _index = 5)),
      ProfileScreen(
        onProfileUpdated: () {
          _dashboardKey.currentState?.loadStats();
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: null,
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: screens[_index],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _destinations,
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.18),
          elevation: 0,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
      ),
    );
  }
}
