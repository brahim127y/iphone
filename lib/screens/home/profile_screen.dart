import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseService.getShopProfile();
    if (!mounted) return;
    nameController.text = profile['name'] ?? 'Tembs';
    phoneController.text = profile['phone'] ?? '';
    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    await DatabaseService.saveShopProfile(
      name: nameController.text,
      phone: phoneController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _showMessage('✅ Modifications enregistrées !');
    widget.onProfileUpdated?.call();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Réinitialiser les données',
            style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700)),
        content: Text(
          'Toutes vos données (produits, clients, ventes) seront supprimées définitivement. Cette action est irréversible !',
          style: GoogleFonts.outfit(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.outfit(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Supprimer tout', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final db = await DatabaseService.database;
        await db.delete('sale_items');
        await db.delete('sales');
        await db.delete('products');
        await db.delete('categories');
        await db.delete('customers');
        _showMessage('✅ Données réinitialisées !');
      } catch (e) {
        _showMessage('Erreur : $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final name = nameController.text.isNotEmpty ? nameController.text : 'Tembs';
    final initials = name.trim().split(' ').map((w) => w[0].toUpperCase()).take(2).join();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // Header profil
        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 25,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: GoogleFonts.outfit(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Application hors ligne · Tembs',
                style: GoogleFonts.outfit(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppGradients.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Mode hors ligne',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Infos boutique
        _sectionTitle('Informations de la boutique'),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              _infoField(
                controller: nameController,
                label: 'Nom de la boutique',
                icon: Icons.store_rounded,
                hint: 'Nom de votre boutique',
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              _divider(),
              const SizedBox(height: 16),
              _infoField(
                controller: phoneController,
                label: 'Téléphone',
                icon: Icons.phone_rounded,
                hint: '+223 XX XX XX XX',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(
          label: 'Enregistrer les modifications',
          onPressed: _saveProfile,
          loading: _saving,
          icon: Icons.save_rounded,
        ),

        const SizedBox(height: 24),

        // Section Application
        _sectionTitle('Application'),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _menuItem(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primaryLight,
                title: 'Version de l\'app',
                trailing: const Text(
                  'v1.0.0 — Hors ligne',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              _divider(),
              _menuItem(
                icon: Icons.storage_rounded,
                iconColor: AppColors.accent,
                title: 'Données stockées localement',
                trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
              ),
              _divider(),
              _menuItem(
                icon: Icons.help_outline_rounded,
                iconColor: AppColors.warning,
                title: 'Aide & Support',
                onTap: () {},
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Bouton réinitialiser
        SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: TextButton.icon(
              onPressed: _clearAllData,
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 20),
              label: Text(
                'Réinitialiser toutes les données',
                style: GoogleFonts.outfit(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Text(
                'Créateur de l\'application',
                style: GoogleFonts.outfit(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bourama Tembely • 74277811',
                style: GoogleFonts.outfit(
                  color: AppColors.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.outfit(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  Widget _divider() => const Divider(color: AppColors.border, height: 1);

  Widget _infoField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryLight, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: GoogleFonts.outfit(color: AppColors.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(color: AppColors.text, fontSize: 14),
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets réutilisables ──────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const GlassCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool loading;
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(icon ?? Icons.check_rounded, color: Colors.white, size: 20),
          label: Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
