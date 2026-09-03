import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/theme.dart';
import 'screens/licence/subscription_lock_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Protection contre les plantages inattendus au démarrage
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Tembs Flutter Error: ${details.exception}');
  };

  try {
    await DatabaseService.database;
  } catch (e) {
    debugPrint('Erreur initialisation base de données: $e');
  }

  runApp(const TembsApp());
}


class TembsApp extends StatelessWidget {
  const TembsApp({super.key});

  bool get _isIOS =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    if (_isIOS) {
      return CupertinoApp(
        title: 'Tembs',
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(
          primaryColor: AppColors.primary,
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppColors.bg,
          barBackgroundColor: CupertinoColors.systemBackground,
          textTheme: CupertinoTextThemeData(
            primaryColor: AppColors.primary,
            textStyle: GoogleFonts.outfit(
              color: AppColors.text,
              fontSize: 16,
            ),
            navTitleTextStyle: GoogleFonts.outfit(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            navLargeTitleTextStyle: GoogleFonts.outfit(
              color: AppColors.text,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
            actionTextStyle: GoogleFonts.outfit(
              color: AppColors.primary,
              fontSize: 17,
            ),
          ),
        ),
        home: const SubscriptionLockScreen(),
      );
    }

    return MaterialApp(
      title: 'Tembs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.light().textTheme,
        ),
        useMaterial3: true,
      ),
      home: const SubscriptionLockScreen(),
    );
  }
}
