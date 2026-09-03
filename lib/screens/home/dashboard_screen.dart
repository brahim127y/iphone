import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../widgets/screen_header.dart';
import '../widgets/ticket_generator.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final Function(String action)? onQuickAction;
  const DashboardScreen({super.key, this.onProfileTap, this.onQuickAction});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  double todayTotal = 0;

  double yesterdayTotal = 0;
  double monthTotal = 0;
  double weekTotal = 0;
  int weekCount = 0;
  int todayCount = 0;
  int lowStockCount = 0;
  int outOfStockCount = 0;
  int productCount = 0;
  int customerCount = 0;
  int salesCount = 0;
  List<Sale> recentSales = [];
  List<Map<String, dynamic>> topProducts = [];
  String shopName = 'Tembs';
  bool loading = true;
  late AnimationController _animCtrl;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  double get _avgBasket => salesCount == 0 ? 0 : monthTotal / salesCount;

  String get _todayVsYesterday {
    if (yesterdayTotal <= 0 && todayTotal <= 0) return 'Comme hier';
    if (yesterdayTotal <= 0) return 'Nouveau CA aujourd\'hui';
    final pct = ((todayTotal - yesterdayTotal) / yesterdayTotal) * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(0)} % vs hier';
  }

  bool get _todayUp => todayTotal >= yesterdayTotal;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    loadStats();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> loadStats() async {
    setState(() => loading = true);
    try {
      final stats = await DatabaseService.getStats();
      final profile = await DatabaseService.getShopProfile();
      final recent = await DatabaseService.getRecentSales(limit: 5);
      final top = await DatabaseService.getTopProducts(limit: 3);
      if (!mounted) return;
      setState(() {
        shopName = profile['name'] ?? 'Tembs';
        todayTotal = stats['todayTotal'] as double;
        yesterdayTotal = stats['yesterdayTotal'] as double;
        weekTotal = (stats['weekTotal'] as num?)?.toDouble() ?? 0.0;
        weekCount = (stats['weekCount'] as int?) ?? 0;
        monthTotal = stats['monthTotal'] as double;
        todayCount = stats['todayCount'] as int;
        productCount = stats['productCount'] as int;
        lowStockCount = stats['lowStockCount'] as int;
        outOfStockCount = stats['outOfStockCount'] as int;
        customerCount = stats['customerCount'] as int;
        salesCount = stats['salesCount'] as int;
        recentSales = recent;
        topProducts = top;
        loading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        ScreenHeader(
          title: _greeting,
          subtitle: 'Tableau de bord • $shopName',
          icon: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
          actions: [
            IconButton(
              onPressed: loadStats,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
            if (widget.onProfileTap != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ],
          bottom: Text(
            _formatDate(),
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: loadStats,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 800;

                if (loading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (isDesktop) {
                  // DESKTOP LAYOUT : Grid 4 colonnes KPIs + 2 colonnes contenu principal
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _heroToday()),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: _kpiTile(
                              label: 'Cette semaine',
                              value: formatFCFA(weekTotal),
                              icon: Icons.date_range_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: _kpiTile(
                              label: 'Ce mois',
                              value: formatFCFA(monthTotal),
                              icon: Icons.calendar_month_rounded,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _kpiTile(
                              label: 'Panier moyen',
                              value: formatFCFA(_avgBasket),
                              icon: Icons.shopping_bag_rounded,
                              color: const Color(0xFF06B6D4),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _kpiTile(
                              label: 'Ventes / semaine',
                              value: '$weekCount',
                              icon: Icons.trending_up_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _miniStatCard('$productCount', 'Produits en stock', Icons.inventory_2_rounded, AppColors.primaryLight),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _miniStatCard('$customerCount', 'Clients enregistrés', Icons.people_alt_rounded, AppColors.accentLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // COLONNE GAUCHE (Santé stock & Alertes)
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('Vue d\'ensemble & Santé Stock'),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(child: _miniStatCard('$salesCount', 'Ventes du mois', Icons.receipt_long_rounded, const Color(0xFF60A5FA))),
                                    const SizedBox(width: 12),
                                    Expanded(child: _miniStatCard('$outOfStockCount', 'Ruptures de stock', Icons.block_rounded, AppColors.danger)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _stockHealthCard(),
                                if (outOfStockCount > 0) ...[
                                  const SizedBox(height: 14),
                                  _alertCard(
                                    title: 'Rupture de stock',
                                    message: '$outOfStockCount produit(s) à 0 — réapprovisionnement requis.',
                                    color: AppColors.danger,
                                    icon: Icons.remove_shopping_cart_rounded,
                                    onTap: () => widget.onQuickAction?.call('view_products'),
                                  ),
                                ],
                                if (lowStockCount > 0) ...[
                                  const SizedBox(height: 12),
                                  _alertCard(
                                    title: 'Stock faible',
                                    message: '$lowStockCount produit(s) avec 3 unités ou moins.',
                                    color: AppColors.warning,
                                    icon: Icons.warning_amber_rounded,
                                    onTap: () => widget.onQuickAction?.call('view_products'),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                _sectionTitle('Actions rapides'),
                                const SizedBox(height: 14),
                                _buildQuickActions(),
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // COLONNE DROITE (Top produits & Dernières ventes)
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('Meilleures ventes du mois'),
                                const SizedBox(height: 14),
                                if (topProducts.isEmpty)
                                  _emptyHint('Les produits les plus vendus apparaîtront ici.')
                                else
                                  ...topProducts.asMap().entries.map((e) => _topProductRow(e.key, e.value)),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(child: _sectionTitle('Dernières ventes')),
                                    if (recentSales.isNotEmpty)
                                      GestureDetector(
                                        onTap: () => widget.onQuickAction?.call('view_sales'),
                                        child: Text(
                                          'Tout voir',
                                          style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (recentSales.isEmpty)
                                  _emptyHint('Aucune vente pour le moment.\nLancez la première depuis les actions rapides.')
                                else
                                  ...recentSales.map(_recentSaleRow),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                // LAYOUT MOBILE
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    _heroToday(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _kpiTile(
                            label: 'Cette semaine',
                            value: formatFCFA(weekTotal),
                            icon: Icons.date_range_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _kpiTile(
                            label: 'Ce mois',
                            value: formatFCFA(monthTotal),
                            icon: Icons.calendar_month_rounded,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _kpiTile(
                            label: 'Panier moyen',
                            value: formatFCFA(_avgBasket),
                            icon: Icons.shopping_bag_rounded,
                            color: const Color(0xFF06B6D4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _kpiTile(
                            label: 'Ventes / semaine',
                            value: '$weekCount',
                            icon: Icons.trending_up_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _sectionTitle('Vue d\'ensemble'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _miniStatCard('$productCount', 'Produits', Icons.inventory_2_rounded, AppColors.primaryLight)),
                        const SizedBox(width: 10),
                        Expanded(child: _miniStatCard('$customerCount', 'Clients', Icons.people_alt_rounded, AppColors.accentLight)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _miniStatCard('$salesCount', 'Ventes / mois', Icons.receipt_long_rounded, const Color(0xFF60A5FA))),
                        const SizedBox(width: 10),
                        Expanded(child: _miniStatCard('$outOfStockCount', 'Ruptures', Icons.block_rounded, AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _stockHealthCard(),
                    if (outOfStockCount > 0) ...[
                      const SizedBox(height: 16),
                      _alertCard(
                        title: 'Rupture de stock',
                        message: '$outOfStockCount produit(s) à 0 — ventes bloquées jusqu\'au réapprovisionnement.',
                        color: AppColors.danger,
                        icon: Icons.remove_shopping_cart_rounded,
                        onTap: () => widget.onQuickAction?.call('view_products'),
                      ),
                    ],
                    if (lowStockCount > 0) ...[
                      const SizedBox(height: 10),
                      _alertCard(
                        title: 'Stock faible',
                        message: '$lowStockCount produit(s) avec 3 unités ou moins.',
                        color: AppColors.warning,
                        icon: Icons.warning_amber_rounded,
                        onTap: () => widget.onQuickAction?.call('view_products'),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _sectionTitle('Meilleures ventes du mois'),
                    const SizedBox(height: 12),
                    if (topProducts.isEmpty)
                      _emptyHint('Les produits les plus vendus apparaîtront ici.')
                    else
                      ...topProducts.asMap().entries.map((e) => _topProductRow(e.key, e.value)),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: _sectionTitle('Dernières ventes')),
                        if (recentSales.isNotEmpty)
                          GestureDetector(
                            onTap: () => widget.onQuickAction?.call('view_sales'),
                            child: Text(
                              'Tout voir',
                              style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (recentSales.isEmpty)
                      _emptyHint('Aucune vente pour le moment.\nLancez la première depuis les actions rapides.')
                    else
                      ...recentSales.map(_recentSaleRow),
                    const SizedBox(height: 22),
                    _sectionTitle('Actions rapides'),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                  ],
                );
              },
            ),
          ),
        ),

      ],
    );
  }

  Widget _heroToday() {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) => Opacity(
        opacity: _animCtrl.value.clamp(0.0, 1.0),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Chiffre du jour',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _todayUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _todayVsYesterday,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                formatFCFA(todayTotal),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                todayCount == 0
                    ? 'Aucune vente aujourd\'hui'
                    : '$todayCount vente${todayCount > 1 ? 's' : ''} aujourd\'hui',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => widget.onQuickAction?.call('new_sale'),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: Text('Nouvelle vente', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _miniStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.outfit(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800)),
                Text(label, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockHealthCard() {
    final inStock = productCount - outOfStockCount;
    final ratio = productCount == 0 ? 0.0 : inStock / productCount;
    return GestureDetector(
      onTap: () => widget.onQuickAction?.call('view_products'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Santé du stock', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                Text(
                  productCount == 0 ? 'Aucun produit' : '$inStock / $productCount disponibles',
                  style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: productCount == 0 ? 0 : ratio,
                minHeight: 8,
                backgroundColor: AppColors.surfaceAlt,
                color: ratio < 0.5
                    ? AppColors.danger
                    : ratio < 0.85
                        ? AppColors.warning
                        : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertCard({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.28), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(message, style: GoogleFonts.outfit(color: color.withValues(alpha: 0.85), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, height: 1.4),
      ),
    );
  }

  Widget _topProductRow(int index, Map<String, dynamic> row) {
    final name = row['name']?.toString() ?? 'Produit';
    final qty = (row['qty'] as num?)?.toInt() ?? 0;
    final revenue = (row['revenue'] as num?)?.toDouble() ?? 0;
    final medals = [AppColors.warning, AppColors.textMuted, const Color(0xFFCD7F32)];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: medals[index.clamp(0, 2)].withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: medals[index.clamp(0, 2)],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$qty vendu${qty > 1 ? 's' : ''}', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(formatFCFA(revenue), style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> openSaleTicket(Sale s) async {
    final items = await DatabaseService.getSaleItems(s.id);
    if (!mounted) return;
    if (items.isEmpty) return;
    final profile = await DatabaseService.getShopProfile();
    if (!mounted) return;
    TicketGenerator.showTicket(
      context: context,
      lines: items.map(TicketLine.fromSaleItem).toList(),
      total: s.total,
      paymentMethod: s.paymentMethod,
      shopName: profile['name'] ?? 'Ma Boutique',
      shopPhone: profile['phone'],
      shopAddress: profile['address'],
      customerName: s.customerName,
      createdAt: s.createdAt,
      receiptNo: s.id.length > 6 ? s.id.substring(s.id.length - 6) : s.id,
    );
  }

  Widget _recentSaleRow(Sale s) {
    return GestureDetector(
      onTap: () => openSaleTicket(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardViolet,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.customerName ?? 'Client de passage',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${s.createdAt.hour.toString().padLeft(2, '0')}:${s.createdAt.minute.toString().padLeft(2, '0')}  •  ${s.paymentMethod}',
                    style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              formatFCFA(s.total),
              style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      const _QuickAction(icon: Icons.add_shopping_cart_rounded, label: 'Nouvelle\nvente', color: AppColors.accent, actionKey: 'new_sale'),
      const _QuickAction(icon: Icons.add_box_rounded, label: 'Ajouter\nproduit', color: AppColors.primaryLight, actionKey: 'add_product'),
      const _QuickAction(icon: Icons.person_add_rounded, label: 'Nouveau\nclient', color: Color(0xFFF472B6), actionKey: 'add_customer'),
      const _QuickAction(icon: Icons.picture_as_pdf_rounded, label: 'Exporter\nPDF', color: AppColors.warning, actionKey: 'export_pdf'),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => widget.onQuickAction?.call(a.actionKey),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: a.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(a.icon, color: a.color, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: AppColors.textSubtle, fontSize: 10, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    const jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${jours[now.weekday - 1]} ${now.day} ${mois[now.month - 1]} ${now.year}';
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String actionKey;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.actionKey});
}
