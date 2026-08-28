import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool loading = false;
  bool _obscurePassword = true;
  bool _isOtpMode = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Renseigne un email valide.', isError: true);
      return;
    }
    if (password.isEmpty) {
      _showMessage('Entre ton mot de passe.', isError: true);
      return;
    }

    setState(() => loading = true);
    try {
      await AuthService.login(
        email: email,
        password: password,
      );
      if (mounted) {
        _showMessage('🎉 Connexion réussie !');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showMessage('$e', isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _handleSendOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Renseigne un email valide.', isError: true);
      return;
    }
    setState(() => loading = true);
    try {
      await supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      if (mounted) {
        Navigator.of(context).push(_pageRoute(OtpScreen(email: email, mode: OtpMode.login)));
      }
    } on AuthException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (e) {
      _showMessage('Aucun compte trouvé pour cet email.', isError: true);
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
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.authHero,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      // Logo Tembs
                      Hero(
                        tag: 'logo',
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 42),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'Tembs',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'Gérez votre boutique avec style',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Card formulaire
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(28),
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
                              Text(
                                'Connexion',
                                style: GoogleFonts.outfit(
                                  color: AppColors.text,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isOtpMode
                                    ? 'Entrez votre email pour recevoir un code OTP'
                                    : 'Connectez-vous à votre compte',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),

                              _buildLabel('Adresse email'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.outfit(color: AppColors.text, fontSize: 15),
                                decoration: const InputDecoration(
                                  hintText: 'vous@exemple.com',
                                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                                ),
                              ),

                              if (!_isOtpMode) ...[
                                const SizedBox(height: 16),
                                _buildLabel('Mot de passe'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: passwordController,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.outfit(color: AppColors.text, fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              GradientButton(
                                label: _isOtpMode ? 'Recevoir le code' : 'Se connecter',
                                onPressed: loading
                                    ? null
                                    : (_isOtpMode ? _handleSendOtp : _handlePasswordLogin),
                                loading: loading,
                                icon: _isOtpMode ? Icons.send_rounded : Icons.login_rounded,
                              ),

                              const SizedBox(height: 12),

                              Center(
                                child: TextButton(
                                  onPressed: () => setState(() => _isOtpMode = !_isOtpMode),
                                  child: Text(
                                    _isOtpMode
                                        ? 'Se connecter avec mot de passe'
                                        : 'Se connecter via code email (OTP)',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Séparateur
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.border, height: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('ou', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13)),
                            ),
                            Expanded(child: Divider(color: AppColors.border, height: 1)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bouton créer compte
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(_pageRoute(const SignupScreen())),
                            icon: const Icon(Icons.person_add_rounded, size: 20),
                            label: Text(
                              'Créer un compte Tembs',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(color: AppColors.textSubtle, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}
