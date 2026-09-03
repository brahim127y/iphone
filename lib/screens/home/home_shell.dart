import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late final PageController _pageController;

  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _productsKey = GlobalKey<ProductsScreenState>();
  final _salesKey = GlobalKey<SalesScreenState>();
  final _customersKey = GlobalKey<CustomersScreenState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int targetIndex) {
    setState(() => _index = targetIndex);
    _refreshCurrentPage(targetIndex);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _refreshCurrentPage(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (index) {
        case 0:
          _dashboardKey.currentState?.loadStats();
          break;
        case 1:
          _productsKey.currentState?.loadData();
          break;
        case 2:
          _salesKey.currentState?.loadData();
          break;
        case 3:
          _customersKey.currentState?.loadData();
          break;
      }
    });
  }


  void _handleQuickAction(String action) {
    switch (action) {
      case 'new_sale':
        _navigateToPage(2);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _salesKey.currentState?.openNewSaleSheet();
        });
        break;
      case 'add_product':
        _navigateToPage(1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _productsKey.currentState?.openAddSheet();
        });
        break;
      case 'add_customer':
        _navigateToPage(3);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _customersKey.currentState?.openAddSheet();
        });
        break;
      case 'export_pdf':
        _navigateToPage(4);
        break;
      case 'view_products':
        _navigateToPage(1);
        break;
      case 'view_sales':
        _navigateToPage(2);
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
        onProfileTap: () => _navigateToPage(5),
        onQuickAction: _handleQuickAction,
      ),
      ProductsScreen(
        key: _productsKey,
        onProfileTap: () => _navigateToPage(5),
      ),
      SalesScreen(
        key: _salesKey,
        onProfileTap: () => _navigateToPage(5),
      ),
      CustomersScreen(
        key: _customersKey,
        onProfileTap: () => _navigateToPage(5),
      ),
      ExportScreen(onProfileTap: () => _navigateToPage(5)),
      ProfileScreen(
        onProfileUpdated: () {
          _dashboardKey.currentState?.loadStats();
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Row(
              children: [
                // SIDEBAR DESKTOP PC (Boutons Larges & Navigation Adaptée)
                Container(
                  width: 270,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(right: BorderSide(color: AppColors.border, width: 1.5)),
                  ),
                  child: Column(
                    children: [
                      // Header Brand PC
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: AppGradients.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tembs',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.primary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    'Gestion Boutique PC',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      const SizedBox(height: 16),

                      // Navigation PC - Boutons de menu larges
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildDesktopNavItem(0, 'Accueil', Icons.home_rounded, Icons.home_outlined),
                            _buildDesktopNavItem(1, 'Produits', Icons.inventory_2_rounded, Icons.inventory_2_outlined),
                            _buildDesktopNavItem(2, 'Ventes', Icons.receipt_long_rounded, Icons.receipt_long_outlined),
                            _buildDesktopNavItem(3, 'Clients', Icons.people_alt_rounded, Icons.people_alt_outlined),
                            _buildDesktopNavItem(4, 'Export PDF', Icons.picture_as_pdf_rounded, Icons.picture_as_pdf_outlined),
                            _buildDesktopNavItem(5, 'Profil & Config', Icons.person_rounded, Icons.person_outline_rounded),
                          ],
                        ),
                      ),

                      // Boutons d'action rapide grand format pour PC
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () => _handleQuickAction('new_sale'),
                                icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 22),
                                label: Text(
                                  '+ Nouvelle Vente',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: () => _handleQuickAction('add_product'),
                                icon: const Icon(Icons.add_box_rounded, color: AppColors.primary, size: 22),
                                label: Text(
                                  '+ Nouveau Produit',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primary, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ZONE DE CONTENU PRINCIPALE PC
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) {
                      setState(() => _index = i);
                      _refreshCurrentPage(i);
                    },
                    children: screens,
                  ),
                ),
              ],
            ),
          );
        }

        // LAYOUT MOBILE (Barre inférieure)
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: null,
          body: SafeArea(
            top: false,
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) {
                setState(() => _index = i);
                _refreshCurrentPage(i);
              },
              children: screens,
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
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
              onDestinationSelected: (i) => _navigateToPage(i),
              destinations: _destinations,
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.primary.withValues(alpha: 0.18),
              elevation: 0,
              height: 68,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopNavItem(int targetIndex, String title, IconData activeIcon, IconData inactiveIcon) {
    final selected = _index == targetIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _navigateToPage(targetIndex),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? activeIcon : inactiveIcon,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: selected ? AppColors.primary : AppColors.text,
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

