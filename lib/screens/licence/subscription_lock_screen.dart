import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/database_service.dart';
import '../home/home_shell.dart';
import '../onboarding/onboarding_screen.dart';

class SubscriptionLockScreen extends StatefulWidget {
  const SubscriptionLockScreen({super.key});

  @override
  State<SubscriptionLockScreen> createState() => _SubscriptionLockScreenState();
}

class _SubscriptionLockScreenState extends State<SubscriptionLockScreen> {
  final codeController = TextEditingController();
  bool loading = true;
  bool checkingCode = false;
  SubscriptionInfo? status;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });
    try {
      final sub = await DatabaseService.getSubscriptionStatus();
      final onboardingDone = await DatabaseService.isOnboardingCompleted();

      if (!sub.isExpired && !sub.isDateTampered) {
        if (!mounted) return;
        if (!onboardingDone) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeShell()),
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        status = sub;
        loading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du controle de licence: $e');
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMsg = 'Erreur initialisation base de donnees : $e';
      });
    }
  }


  Future<void> _recharge() async {
    final code = codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => checkingCode = true);
    final days = await DatabaseService.activateLicenseCode(code);
    setState(() => checkingCode = false);

    if (days != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Licence prolongée de $days jour${days > 1 ? 's' : ''} avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
      _checkStatus();
    } else {
      setState(() {
        errorMsg = 'Code de recharge invalide ou expiré.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final isTampered = status?.isDateTampered ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: isTampered ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFB71C1C)]) : AppGradients.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isTampered ? AppColors.danger : AppColors.primary).withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    isTampered ? Icons.warning_amber_rounded : Icons.lock_clock_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isTampered ? 'Date système incorrecte' : 'Abonnement expiré',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isTampered
                      ? 'La date de votre téléphone a été modifiée. Veuillez régler l\'heure et la date automatiques de votre appareil.'
                      : 'Votre période d\'abonnement est arrivée à terme. Saisissez un code de recharge pour déverrouiller l\'application.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                if (isTampered) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _checkStatus,
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      label: Text(
                        'J\'ai réglé la date, vérifier',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
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
                        Text(
                          'Code de recharge d\'abonnement',
                          style: GoogleFonts.outfit(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: GoogleFonts.outfit(
                            color: AppColors.text,
                            fontSize: 18,
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
                          onSubmitted: (_) => _recharge(),
                        ),
                        if (errorMsg != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            errorMsg!,
                            style: GoogleFonts.outfit(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: checkingCode ? null : _recharge,
                        icon: checkingCode
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: Text(
                          checkingCode ? 'Vérification...' : 'Recharger et Déverrouiller',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
