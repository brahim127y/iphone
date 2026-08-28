import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;
import '../../main.dart';
import '../../config/theme.dart';

enum OtpMode { login, signup }

class OtpScreen extends StatefulWidget {
  final String? email;
  final String? phone;
  final OtpMode mode;

  const OtpScreen({
    super.key,
    this.email,
    this.phone,
    required this.mode,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final codeController = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  bool loading = false;
  int _countdown = 60;
  Timer? _timer;
  String currentCode = '';

  bool get isEmail => widget.email != null;
  String get destinationLabel => isEmail ? widget.email! : widget.phone!;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_countdown > 0) _countdown--;
        else t.cancel();
      });
    });
  }

  Future<void> _resendCode() async {
    setState(() => loading = true);
    try {
      if (isEmail) {
        await supabase.auth.signInWithOtp(email: widget.email!);
        _showMessage('✅ Nouveau code envoyé à ${widget.email}');
      }
      _startCountdown();
    } catch (e) {
      _showMessage('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (currentCode.length < 6) {
      _showMessage('Entre le code à 6 chiffres.', isError: true);
      return;
    }
    setState(() => loading = true);
    try {
      if (isEmail) {
        await supabase.auth.verifyOTP(
          email: widget.email!,
          token: currentCode,
          type: OtpType.email,
        );
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showMessage('Code incorrect ou expiré. Réessaie.', isError: true);
      codeController.clear();
      setState(() => currentCode = '');
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

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Header dégradé
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Bouton retour
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Icon + titre
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 32),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Code de vérification',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            destinationLabel,
                            style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Card OTP
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Entrez le code à 6 chiffres envoyé à votre adresse email',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                          ),

                          const SizedBox(height: 24),

                          PinCodeTextField(
                            appContext: context,
                            length: 6,
                            controller: codeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            animationType: AnimationType.scale,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(10),
                              fieldHeight: 46,
                              fieldWidth: 38,
                              activeFillColor: AppColors.surfaceAlt,
                              inactiveFillColor: AppColors.bg,
                              selectedFillColor: AppColors.surfaceAlt,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.border,
                              selectedColor: AppColors.primary,
                            ),
                            enableActiveFill: true,
                            textStyle: GoogleFonts.outfit(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            onChanged: (val) => setState(() => currentCode = val),
                            onCompleted: (_) => _verifyCode(),
                          ),

                          const SizedBox(height: 24),

                          GradientButton(
                            label: 'Vérifier le code',
                            onPressed: loading ? null : _verifyCode,
                            loading: loading,
                            icon: Icons.verified_rounded,
                          ),

                          const SizedBox(height: 20),

                          // Renvoyer code
                          _countdown > 0
                              ? Text(
                                  'Renvoyer le code dans $_countdown s',
                                  style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                                )
                              : TextButton(
                                  onPressed: loading ? null : _resendCode,
                                  child: Text(
                                    '🔁 Renvoyer le code',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
