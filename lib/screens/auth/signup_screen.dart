import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool loading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text;

      await AuthService.signup(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;
      _showMessage('🎉 Compte créé avec succès ! Bienvenue.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _showMessage('$e', isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  PageRoute _pageRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Fond décoratif haut
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.authHero,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
              child: Stack(children: [
                Positioned(
                  top: -40,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ]),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 16),
                          // Bouton retour
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Créer un compte',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Rejoins la famille Tembs 🚀',
                            style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                          ),

                          const SizedBox(height: 32),

                          // Formulaire
                          Form(
                            key: _formKey,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.10),
                                    blurRadius: 40,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nom complet
                                  _label('Nom complet'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: nameController,
                                    keyboardType: TextInputType.name,
                                    textCapitalization: TextCapitalization.words,
                                    style: GoogleFonts.outfit(color: AppColors.text, fontSize: 15),
                                    decoration: const InputDecoration(
                                      hintText: 'Ibrahima Diallo',
                                      prefixIcon: Icon(Icons.badge_rounded, size: 20),
                                    ),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Renseigne ton nom complet' : null,
                                  ),

                                  const SizedBox(height: 20),

                                  _label('Adresse email'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: GoogleFonts.outfit(color: AppColors.text, fontSize: 15),
                                    decoration: const InputDecoration(
                                      hintText: 'vous@exemple.com',
                                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                                    ),
                                    validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                                  ),

                                  const SizedBox(height: 20),

                                  _label('Mot de passe'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: passwordController,
                                    obscureText: _obscurePassword,
                                    style: GoogleFonts.outfit(color: AppColors.text, fontSize: 15),
                                    decoration: InputDecoration(
                                      hintText: 'Min. 6 caractères',
                                      prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
                                  ),

                                  const SizedBox(height: 28),

                                  GradientButton(
                                    label: 'Créer mon compte',
                                    onPressed: loading ? null : _handleSignup,
                                    loading: loading,
                                    icon: Icons.person_add_rounded,
                                    gradient: AppGradients.accent,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Center(
                            child: Text(
                              'En créant un compte, vous acceptez nos\nConditions d\'utilisation.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String label) => Text(
        label,
        style: GoogleFonts.outfit(color: AppColors.textSubtle, fontSize: 13, fontWeight: FontWeight.w600),
      );
}
