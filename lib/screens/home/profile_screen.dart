import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool loading = true;
  bool saving = false;
  Map<String, dynamic>? profile;

  String get userEmail => AuthService.currentUserEmail;
  String get userId => AuthService.currentUserId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => loading = true);
    try {
      final data =
          await supabase.from('profiles').select().eq('id', userId).maybeSingle();
      if (mounted) {
        setState(() {
          profile = data;
          nameController.text = data?['full_name'] ?? '';
          phoneController.text = data?['phone'] ?? '';
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    setState(() => saving = true);
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'full_name': name,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _showMessage('✅ Profil mis à jour !');
    } catch (e) {
      _showMessage('Erreur : $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Déconnexion',
          style: GoogleFonts.outfit(
              color: AppColors.text, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Es-tu sûr de vouloir te déconnecter ?',
          style: GoogleFonts.outfit(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: GoogleFonts.outfit(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Déconnecter',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.logout();
    }
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

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final name = nameController.text.isNotEmpty
        ? nameController.text
        : userEmail.split('@').first;
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w[0].toUpperCase()).take(2).join()
        : '?';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // Header profil
        Center(
          child: Column(
            children: [
              // Avatar avec initiales
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
                userEmail,
                style: GoogleFonts.outfit(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppGradients.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Compte vérifié',
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

        // Section : Informations personnelles
        _sectionTitle('Informations personnelles'),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              _infoField(
                controller: nameController,
                label: 'Nom complet',
                icon: Icons.badge_rounded,
                hint: 'Votre nom complet',
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

        const SizedBox(height: 12),

        // Email (non modifiable)
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.email_outlined,
                    color: AppColors.textMuted, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: GoogleFonts.outfit(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                    Text(
                      userEmail,
                      style: GoogleFonts.outfit(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Non modifiable',
                  style: GoogleFonts.outfit(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Bouton sauvegarder
        GradientButton(
          label: 'Sauvegarder',
          onPressed: _saveProfile,
          loading: saving,
          icon: Icons.save_rounded,
        ),

        const SizedBox(height: 24),

        // Section : Application
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
                  'v1.0.0',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
              _divider(),
              _menuItem(
                icon: Icons.security_rounded,
                iconColor: AppColors.accent,
                title: 'Sécurité & Confidentialité',
                onTap: () {},
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

        // Bouton déconnexion
        SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: TextButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.danger, size: 20),
              label: Text(
                'Se déconnecter',
                style: GoogleFonts.outfit(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        // Infos du créateur
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

  Widget _divider() =>
      const Divider(color: AppColors.border, height: 1);

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
              Text(
                label,
                style: GoogleFonts.outfit(
                    color: AppColors.textMuted, fontSize: 11),
              ),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: GoogleFonts.outfit(
                    color: AppColors.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: const UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.primary, width: 1.5),
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
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}
