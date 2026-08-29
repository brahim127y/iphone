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

  @override
  Widget build(BuildContext context) {
    // Couleur active de la tab bar — violet Tembs
    const activeColor = AppColors.primary;
    const inactiveColor = AppColors.textMuted;

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
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
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (_) => _IOSScreenWrapper(
                child: DashboardScreen(
                  key: _dashboardKey,
                  onProfileTap: () => setState(() => _index = 5),
                  onQuickAction: _handleQuickAction,
                ),
              ),
            );
          case 1:
            return CupertinoTabView(
              builder: (_) => _IOSScreenWrapper(
                child: ProductsScreen(
                  key: _productsKey,
                  onProfileTap: () => setState(() => _index = 5),
                ),
              ),
            );
          case 2:
            return CupertinoTabView(
              builder: (_) => _IOSScreenWrapper(
                child: SalesScreen(
                  key: _salesKey,
                  onProfileTap: () => setState(() => _index = 5),
                ),
              ),
            );
          case 3:
            return CupertinoTabView(
              builder: (_) => _IOSScreenWrapper(
                child: CustomersScreen(
                  key: _customersKey,
                  onProfileTap: () => setState(() => _index = 5),
                ),
              ),
            );
          case 4:
            return CupertinoTabView(
              builder: (_) => _IOSScreenWrapper(
                child: ExportScreen(
                  onProfileTap: () => setState(() => _index = 5),
                ),
              ),
            );
          case 5:
          default:
            return CupertinoTabView(
              builder: (_) => _IOSScreenWrapper(
                child: ProfileScreen(
                  onProfileUpdated: () {
                    _dashboardKey.currentState?.loadStats();
                  },
                ),
              ),
            );
        }
      },
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
