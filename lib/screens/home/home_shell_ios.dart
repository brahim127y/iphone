import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, Scaffold, ScaffoldMessenger;
import '../../config/theme.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'customers_screen.dart';
import 'export_screen.dart';
import 'profile_screen.dart';

class HomeShellIOS extends StatefulWidget {
  const HomeShellIOS({super.key});

  @override
  State<HomeShellIOS> createState() => _HomeShellIOSState();
}

class _HomeShellIOSState extends State<HomeShellIOS> {
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


  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.primary;
    const inactiveColor = AppColors.textMuted;

    final screens = [
      _IOSScreenWrapper(
        child: DashboardScreen(
          key: _dashboardKey,
          onProfileTap: () => _navigateToPage(5),
          onQuickAction: _handleQuickAction,
        ),
      ),
      _IOSScreenWrapper(
        child: ProductsScreen(
          key: _productsKey,
          onProfileTap: () => _navigateToPage(5),
        ),
      ),
      _IOSScreenWrapper(
        child: SalesScreen(
          key: _salesKey,
          onProfileTap: () => _navigateToPage(5),
        ),
      ),
      _IOSScreenWrapper(
        child: CustomersScreen(
          key: _customersKey,
          onProfileTap: () => _navigateToPage(5),
        ),
      ),
      _IOSScreenWrapper(
        child: ExportScreen(
          onProfileTap: () => _navigateToPage(5),
        ),
      ),
      _IOSScreenWrapper(
        child: ProfileScreen(
          onProfileUpdated: () {
            _dashboardKey.currentState?.loadStats();
          },
        ),
      ),
    ];

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: Column(
        children: [
          Expanded(
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
          CupertinoTabBar(
            currentIndex: _index,
            onTap: (i) => _navigateToPage(i),
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            backgroundColor: CupertinoColors.systemBackground.withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.house),
                activeIcon: Icon(CupertinoIcons.house_fill),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.cube_box),
                activeIcon: Icon(CupertinoIcons.cube_box_fill),
                label: 'Produits',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.doc_text),
                activeIcon: Icon(CupertinoIcons.doc_text_fill),
                label: 'Ventes',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person_2),
                activeIcon: Icon(CupertinoIcons.person_2_fill),
                label: 'Clients',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.arrow_down_doc),
                activeIcon: Icon(CupertinoIcons.arrow_down_doc_fill),
                label: 'Export',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person),
                activeIcon: Icon(CupertinoIcons.person_fill),
                label: 'Profil',
              ),
            ],
          ),
        ],
      ),
    );
  }

}

/// Wrapper qui fournit un ancêtre [Scaffold] Material pour que les écrans
/// existants (ScaffoldMessenger, BottomSheet, SnackBar, showDialog, etc.)
/// fonctionnent correctement à l'intérieur d'un contexte [CupertinoApp].
class _IOSScreenWrapper extends StatelessWidget {
  final Widget child;

  const _IOSScreenWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg,
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: AppColors.bg,
          body: child,
        ),
      ),
    );
  }
}
