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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onProfileTap: () => setState(() => _index = 5)),
      ProductsScreen(onProfileTap: () => setState(() => _index = 5)),
      SalesScreen(onProfileTap: () => setState(() => _index = 5)),
      CustomersScreen(onProfileTap: () => setState(() => _index = 5)),
      ExportScreen(onProfileTap: () => setState(() => _index = 5)),
      const ProfileScreen(),
    ];
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
            child: _screens[_index],
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
