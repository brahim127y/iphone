import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/database_service.dart';
import '../home/home_shell.dart';

const String kInstallationAccessCode = '453216';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  
  bool _codeVerified = false;
  bool _saving = false;
  bool _loadingSub = true;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _checkInitialSub();
  }

  Future<void> _checkInitialSub() async {
    final sub = await DatabaseService.getSubscriptionStatus();
    if (mounted) {
      setState(() {
        if (!sub.isExpired && !sub.isDateTampered) {
          _codeVerified = true;
        }
        _loadingSub = false;
      });
    }
  }

  @override
  void dispose() {

    codeController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final entered = codeController.text.trim();
    final days = await DatabaseService.activateLicenseCode(entered);
    if (days != null) {
      setState(() {
        _codeVerified = true;
        _codeError = null;
      });
    } else {
      setState(() {
        _codeError = 'Code d\'accès incorrect ou non reconnu. Accès refusé.';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await DatabaseService.saveShopProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
      );
      await DatabaseService.setOnboardingCompleted(true);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildFieldCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (required) ...[
                      const SizedBox(width: 4),
                      Text('*', style: GoogleFonts.outfit(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (_loadingSub) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 700;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 680 : 450),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo Rond + Marque Tembs
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 46,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Tembs',
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            !_codeVerified
                                ? 'Activation de la licence d\'installation'
                                : 'Bienvenue ! Configurez votre boutique',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: AppColors.textMuted,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 36),

                          if (!_codeVerified) ...[
                            // ÉTAPE 1 : Code de sécurité
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _codeError != null ? AppColors.danger : AppColors.border,
                                  width: _codeError != null ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Code de sécurité requis',
                                          style: GoogleFonts.outfit(
                                            color: AppColors.text,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Saisissez le code d\'accès à 6 chiffres d\'installation pour déverrouiller l\'application.',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Code d\'installation (6 chiffres) *',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textSubtle,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: codeController,
                                    keyboardType: TextInputType.number,
                                    obscureText: true,
                                    maxLength: 6,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.text,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 4,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '••••••',
                                      hintStyle: GoogleFonts.outfit(letterSpacing: 4, color: AppColors.textMuted),
                                      prefixIcon: const Icon(Icons.key_rounded, size: 20),
                                      fillColor: AppColors.surfaceAlt,
                                      counterText: '',
                                    ),
                                    onSubmitted: (_) => _verifyCode(),
                                  ),
                                  if (_codeError != null) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _codeError!,
                                            style: GoogleFonts.outfit(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _verifyCode,
                                  icon: const Icon(Icons.verified_user_rounded, color: Colors.white),
                                  label: Text(
                                    'Activer et continuer',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // ÉTAPE 2 : Infos Boutique — Layout Adapté PC & Mobile
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Votre Commerce',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.text,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Ces infos apparaîtront sur vos tickets et rapports',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            if (isDesktop) ...[
                              // Sur PC : Nom et Téléphone côte à côte sur 2 colonnes
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildFieldCard(
                                      icon: Icons.store_rounded,
                                      iconColor: AppColors.primary,
                                      iconBg: AppColors.primary.withValues(alpha: 0.12),
                                      label: 'Nom de la boutique',
                                      required: true,
                                      child: TextFormField(
                                        controller: nameController,
                                        textCapitalization: TextCapitalization.words,
                                        style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 15),
                                        validator: (v) => (v == null || v.trim().isEmpty)
                                            ? 'Veuillez saisir le nom de votre boutique'
                                            : null,
                                        decoration: InputDecoration(
                                          hintText: 'Ex: Chic Fashion Bamako',
                                          hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildFieldCard(
                                      icon: Icons.phone_rounded,
                                      iconColor: const Color(0xFF10B981),
                                      iconBg: const Color(0xFF10B981).withValues(alpha: 0.12),
                                      label: 'Numéro de téléphone',
                                      required: true,
                                      child: TextFormField(
                                        controller: phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 15),
                                        validator: (v) => (v == null || v.trim().isEmpty)
                                            ? 'Veuillez saisir votre numéro de téléphone'
                                            : null,
                                        decoration: InputDecoration(
                                          hintText: 'Ex: +223 70 00 00 00',
                                          hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Sur Mobile : 1 seule colonne
                              _buildFieldCard(
                                icon: Icons.store_rounded,
                                iconColor: AppColors.primary,
                                iconBg: AppColors.primary.withValues(alpha: 0.12),
                                label: 'Nom de la boutique',
                                required: true,
                                child: TextFormField(
                                  controller: nameController,
                                  textCapitalization: TextCapitalization.words,
                                  style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 15),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Veuillez saisir le nom de votre boutique'
                                      : null,
                                  decoration: InputDecoration(
                                    hintText: 'Ex: Chic Fashion Bamako',
                                    hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildFieldCard(
                                icon: Icons.phone_rounded,
                                iconColor: const Color(0xFF10B981),
                                iconBg: const Color(0xFF10B981).withValues(alpha: 0.12),
                                label: 'Numéro de téléphone',
                                required: true,
                                child: TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 15),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Veuillez saisir votre numéro de téléphone'
                                      : null,
                                  decoration: InputDecoration(
                                    hintText: 'Ex: +223 70 00 00 00',
                                    hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            // Carte Quartier / Localisation
                            _buildFieldCard(
                              icon: Icons.location_on_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              label: 'Quartier / Localisation',
                              required: true,
                              child: TextFormField(
                                controller: addressController,
                                style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 15),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Veuillez saisir votre quartier ou ville'
                                    : null,
                                decoration: InputDecoration(
                                  hintText: 'Ex: Bamako, Badalabougou',
                                  hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Note info ticket
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Ces informations s\'afficheront en en-tête de chaque ticket de vente et rapport mensuel.',
                                      style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _saving ? null : _submit,
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                                  label: Text(
                                    _saving ? 'Enregistrement...' : 'Lancer l\'application PC',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

  }
}
