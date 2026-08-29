import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/database_service.dart';
import '../widgets/screen_header.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final Function(String action)? onQuickAction;
  const DashboardScreen({super.key, this.onProfileTap, this.onQuickAction});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  double todayTotal = 0;
  double monthTotal = 0;
  int lowStockCount = 0;
  int productCount = 0;
  int customerCount = 0;
  int salesCount = 0;
  String shopName = 'Tembs';
  bool loading = true;
  late AnimationController _animCtrl;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String get _userFirstName => shopName;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
      if (!mounted) return;
      setState(() {
        shopName = profile['name'] ?? 'Tembs';
        todayTotal = stats['todayTotal'] as double;
        monthTotal = stats['monthTotal'] as double;
        productCount = stats['productCount'] as int;
        lowStockCount = stats['lowStockCount'] as int;
        customerCount = stats['customerCount'] as int;
        salesCount = stats['salesCount'] as int;
        loading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: '$_greeting${_userFirstName.isNotEmpty ? ', $_userFirstName' : ''} 👋',
          subtitle: _formatDate(),
          icon: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
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
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: loadStats,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else ...[
            // Cartes principales
            _buildMainCard(
              label: 'Ventes aujourd\'hui',
              value: formatFCFA(todayTotal),
              icon: Icons.today_rounded,
              gradient: AppGradients.primary,
              subtitle: 'Mis à jour à l\'instant',
            ),

            const SizedBox(height: 14),

            _buildMainCard(
              label: 'Ventes ce mois',
              value: formatFCFA(monthTotal),
              icon: Icons.calendar_month_rounded,
              gradient: AppGradients.emerald,
              subtitle: '$salesCount ventes réalisées',
            ),

            const SizedBox(height: 20),

            // Mini stats grid
            Text(
              'Vue d\'ensemble',
              style: GoogleFonts.outfit(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _miniStatCard(
                    value: '$productCount',
                    label: 'Produits',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.primaryLight,
                    bgGradient: AppGradients.card,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _miniStatCard(
                    value: '$customerCount',
                    label: 'Clients',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.accentLight,
                    bgGradient: AppGradients.emerald,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _miniStatCard(
                    value: '$salesCount',
                    label: 'Ventes/mois',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF60A5FA),
                    bgGradient: AppGradients.cyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _miniStatCard(
                    value: '$lowStockCount',
                    label: 'Stock faible',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    bgGradient: AppGradients.amber,
                  ),
                ),
              ],
            ),

            // Alerte stock faible
            if (lowStockCount > 0) ...[
              const SizedBox(height: 20),
              _buildAlert(),
            ],

            const SizedBox(height: 20),

            // Actions rapides
            Text(
              'Actions rapides',
              style: GoogleFonts.outfit(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context),
          ],
        ],
      ),
    ),
  ),
],
);
  }

  Widget _buildHeader() {
    final firstName = _userFirstName;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting${firstName.isNotEmpty ? ', $firstName' : ''} 👋',
                style: GoogleFonts.outfit(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(),
                style: GoogleFonts.outfit(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        // Bouton refresh
        GestureDetector(
          onTap: loadStats,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: AppColors.textMuted, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard({
    required String label,
    required String value,
    required IconData icon,
    required Gradient gradient,
    String? subtitle,
  }) {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) => Opacity(
        opacity: _animCtrl.value.clamp(0.0, 1.0),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded,
                              color: Colors.white60, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required Gradient bgGradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
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
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock critique',
                  style: GoogleFonts.outfit(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$lowStockCount produit(s) en stock faible (≤ 3 unités)',
                  style: GoogleFonts.outfit(
                    color: AppColors.warning.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
          icon: Icons.add_shopping_cart_rounded,
          label: 'Nouvelle\nvente',
          color: AppColors.accent,
          actionKey: 'new_sale'),
      _QuickAction(
          icon: Icons.add_box_rounded,
          label: 'Ajouter\nproduit',
          color: AppColors.primaryLight,
          actionKey: 'add_product'),
      _QuickAction(
          icon: Icons.person_add_rounded,
          label: 'Nouveau\nclient',
          color: const Color(0xFFF472B6),
          actionKey: 'add_customer'),
      _QuickAction(
          icon: Icons.picture_as_pdf_rounded,
          label: 'Exporter\nPDF',
          color: AppColors.warning,
          actionKey: 'export_pdf'),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _quickActionButton(a),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _quickActionButton(_QuickAction action) {
    return InkWell(
      onTap: () {
        if (widget.onQuickAction != null) {
          widget.onQuickAction!(action.actionKey);
        }
      },
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
                color: action.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.textSubtle,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    const jours = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
      'Vendredi', 'Samedi', 'Dimanche'
    ];
    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    final jour = jours[now.weekday - 1];
    final m = mois[now.month - 1];
    return '$jour ${now.day} $m ${now.year}';
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String actionKey;
  const _QuickAction(
      {required this.icon, required this.label, required this.color, required this.actionKey});
}
