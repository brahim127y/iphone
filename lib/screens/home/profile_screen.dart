import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../services/backup_service.dart';
import '../../services/database_service.dart';


class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final nameController = TextEditingController();

  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  bool _saving = false;
  bool _loading = true;

  SubscriptionInfo? _subInfo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseService.getShopProfile();
    final sub = await DatabaseService.getSubscriptionStatus();
    if (!mounted) return;
    nameController.text = profile['name'] ?? '';
    phoneController.text = profile['phone'] ?? '';
    addressController.text = profile['address'] ?? '';
    setState(() {
      _subInfo = sub;
      _loading = false;
    });
  }

  Future<void> _exportData() async {
    setState(() => _saving = true);
    try {
      final path = await BackupService.exportData();
      if (!mounted) return;
      final shouldShare = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
          title: Text('Export réussi !', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fichier sauvegardé dans Téléchargements :', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                child: Text(path.split('/').last, style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              Text('Voulez-vous aussi partager ce fichier (WhatsApp, Bluetooth, etc.) ?', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Non, fermer', style: GoogleFonts.outfit(color: AppColors.textMuted))),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.share_rounded, size: 16),
              label: Text('Partager', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      );
      if (shouldShare == true) await BackupService.shareBackup(path);
    } catch (e) {
      _showMessage('Erreur export : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _importData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
        title: Text('Importer des données', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700)),
        content: Text(
          'Sélectionnez votre fichier de sauvegarde (.json). Toutes les données actuelles (produits, clients, ventes) seront remplacées par celles du fichier importé.\n\nVotre abonnement ne sera pas affecté.',
          style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: GoogleFonts.outfit(color: AppColors.textMuted))),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.folder_open_rounded, size: 16),
            label: Text('Parcourir le téléphone', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickerResult == null || pickerResult.files.isEmpty || pickerResult.files.single.path == null) {
        return;
      }

      final selectedPath = pickerResult.files.single.path!;
      setState(() => _saving = true);
      final file = File(selectedPath);
      if (!await file.exists()) {
        _showMessage('❌ Fichier introuvable.');
        return;
      }
      final content = await file.readAsString();
      final result = await BackupService.importData(content);
      if (!mounted) return;
      _showMessage(result.message);
      if (result.success) {
        _loadProfile();
        widget.onProfileUpdated?.call();
      }
    } catch (e) {
      _showMessage('Erreur lors du choix du fichier : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  Future<void> _rechargeLicenseDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
        title: Text('Recharger ma licence', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saisissez votre code de recharge (ex: 562365 pour 1 mois ou 214563 pour 3 mois)',
              style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 3),
              decoration: const InputDecoration(
                hintText: '••••••',
                prefixIcon: Icon(Icons.key_rounded, size: 20),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final days = await DatabaseService.activateLicenseCode(result);
      if (days != null) {
        _showMessage('✅ Licence rechargée de $days jours avec succès !');
        _loadProfile();
      } else {
        _showMessage('❌ Code de recharge invalide.');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (nameController.text.trim().isEmpty) {
      _showMessage('Le nom de la boutique ne peut pas être vide.');
      return;
    }
    setState(() => _saving = true);
    await DatabaseService.saveShopProfile(
      name: nameController.text,
      phone: phoneController.text,
      address: addressController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _showMessage('✅ Modifications de la boutique enregistrées !');
    widget.onProfileUpdated?.call();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
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
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final name = nameController.text.isNotEmpty ? nameController.text : 'Tembs';
    final initials = name.trim().split(' ').map((w) => w[0].toUpperCase()).take(2).join();

    return ListView(
      physics: const BouncingScrollPhysics(),
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
              const SizedBox(height: 16),
              _divider(),
              const SizedBox(height: 16),
              _infoField(
                controller: addressController,
                label: 'Quartier / Emplacement',
                icon: Icons.location_on_rounded,
                hint: 'Ex: Bamako, Badalabougou',
                keyboardType: TextInputType.streetAddress,
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

        // Section Licence & Abonnement
        _sectionTitle('Licence & Abonnement'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: (_subInfo?.isExpired ?? false)
                          ? AppColors.dangerLight
                          : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      (_subInfo?.isExpired ?? false)
                          ? Icons.warning_amber_rounded
                          : Icons.workspace_premium_rounded,
                      color: (_subInfo?.isExpired ?? false) ? AppColors.danger : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_subInfo?.isExpired ?? false) ? 'Abonnement expiré' : 'Licence Active',
                          style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          _subInfo?.expiryDate != null
                              ? 'Expire le ${DateFormat('dd/MM/yyyy').format(_subInfo!.expiryDate!)}'
                              : 'Aucune licence active',
                          style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_subInfo?.expiryDate != null && !(_subInfo?.isExpired ?? false))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_subInfo!.remainingDays}j restant${_subInfo!.remainingDays > 1 ? 's' : ''}',
                        style: GoogleFonts.outfit(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _rechargeLicenseDialog,
                  icon: const Icon(Icons.key_rounded, size: 18, color: AppColors.primary),
                  label: Text('Recharger avec un code', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section Sauvegarde & Restauration
        _sectionTitle('Sauvegarde & Restauration'),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _menuItem(
                icon: Icons.cloud_download_rounded,
                iconColor: AppColors.primary,
                title: 'Exporter toutes les données',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.cardViolet, borderRadius: BorderRadius.circular(6)),
                  child: Text('JSON', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 10)),
                ),
                onTap: _exportData,
              ),
              _divider(),
              _menuItem(
                icon: Icons.cloud_upload_rounded,
                iconColor: AppColors.accent,
                title: 'Importer une sauvegarde',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                onTap: _importData,
              ),
            ],
          ),
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
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
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
