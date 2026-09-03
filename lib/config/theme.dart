import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ============================================================
// TEMBS — Thème Premium Clair & Moderne
// ============================================================

class AppColors {
  // Backgrounds — fond clair propre
  static const bg = Color(0xFFF8F6FF);          // Blanc lavande ultra doux
  static const surface = Color(0xFFFFFFFF);      // Blanc pur pour les cards
  static const surfaceAlt = Color(0xFFF3F0FF);   // Lavande très légère
  static const surfaceGlass = Color(0xCCFFFFFF);
  static const border = Color(0xFFE8E3FF);       // Bordure violet doux
  static const borderGlow = Color(0xFF7C3AED);

  // Text
  static const text = Color(0xFF1A1033);         // Violet très sombre
  static const textMuted = Color(0xFF8B7EA8);    // Violet moyen
  static const textSubtle = Color(0xFF6B5E8A);   // Violet intermédiaire

  // Primary — Violet électrique
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFF9F67FA);
  static const primaryDark = Color(0xFF5B21B6);

  // Accent — Coral/Rose vif
  static const accent = Color(0xFFFF6B6B);
  static const accentLight = Color(0xFFFF8E8E);
  static const accentOrange = Color(0xFFFF8C42);

  // Success, Warning, Danger
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEE2E2);

  // Card tints (légers pour mode clair)
  static const cardViolet = Color(0xFFF3F0FF);
  static const cardEmerald = Color(0xFFD1FAE5);
  static const cardAmber = Color(0xFFFEF3C7);
  static const cardCyan = Color(0xFFCFFAFE);
  static const cardRose = Color(0xFFFFE4E6);
  static const cardBlue = Color(0xFFDBEAFE);

  static const onPrimary = Colors.white;
  static const onDark = Colors.white;
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF9F67FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accent = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8C42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const success = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const background = LinearGradient(
    colors: [Color(0xFFF8F6FF), Color(0xFFF1EEFF), Color(0xFFF8F6FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Gradient Hero pour pages d'auth
  static const authHero = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF9F67FA), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const card = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF9F67FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const emerald = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cyan = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0E7490)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const amber = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const rose = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8C42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surface,
    onPrimary: AppColors.onPrimary,
    onSurface: AppColors.text,
    error: AppColors.danger,
  ),
  textTheme: GoogleFonts.outfitTextTheme(
    const TextTheme(
      displayLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
      displayMedium: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: AppColors.text, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: AppColors.text),
      bodyMedium: TextStyle(color: AppColors.text),
      bodySmall: TextStyle(color: AppColors.textMuted),
      labelLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bg,
    foregroundColor: AppColors.text,
    elevation: 0,
    centerTitle: false,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: GoogleFonts.outfit(
      color: AppColors.text,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shadowColor: AppColors.primary.withValues(alpha: 0.08),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.border),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.primary.withValues(alpha: 0.12),
    shadowColor: AppColors.primary.withValues(alpha: 0.08),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.primary, size: 24);
      }
      return const IconThemeData(color: AppColors.textMuted, size: 22);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GoogleFonts.outfit(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        );
      }
      return GoogleFonts.outfit(
        color: AppColors.textMuted,
        fontSize: 11,
      );
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceAlt,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    hintStyle: const TextStyle(color: AppColors.textMuted),
    prefixIconColor: AppColors.textMuted,
    suffixIconColor: AppColors.textMuted,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.border, width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
    ),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.surfaceAlt,
    labelStyle: const TextStyle(color: AppColors.text),
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    selectedColor: AppColors.primary,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.text,
    contentTextStyle: GoogleFonts.outfit(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: AppColors.border),
    ),
    elevation: 8,
    shadowColor: AppColors.primary.withValues(alpha: 0.15),
  ),
);

// ========================
// Formater en FCFA
// ========================
String formatFCFA(num amount) {
  final formatter = NumberFormat.decimalPattern('fr_FR');
  return '${formatter.format(amount.round())} FCFA';
}

// ========================
// Widget : GlassCard (mode clair)
// ========================
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Gradient? gradient;
  final double borderRadius;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.borderRadius = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (color ?? AppColors.surface) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: gradient != null ? Colors.white.withValues(alpha: 0.2) : AppColors.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ========================
// Widget : GradientButton
// ========================
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Gradient? gradient;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.gradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : (gradient ?? AppGradients.primary),
          color: onPressed == null ? AppColors.surfaceAlt : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.onPrimary,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ========================
// Widget : StatCard colorée
// ========================
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final Color bgColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
