import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';

class AppUser {
  final String id;
  final String email;
  final String fullName;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        fullName: json['full_name'] ?? '',
      );
}

class AuthService {
  static const _currentSessionKey = 'tembs_current_user_session';
  static const _registeredAccountsKey = 'tembs_registered_accounts';

  static final ValueNotifier<AppUser?> currentUserNotifier = ValueNotifier<AppUser?>(null);

  static AppUser? get currentUser => currentUserNotifier.value;
  static bool get isAuthenticated => currentUserNotifier.value != null;

  static String get currentUserId => currentUser?.id ?? supabase.auth.currentUser?.id ?? 'local_user_id';
  static String get currentUserEmail => currentUser?.email ?? supabase.auth.currentUser?.email ?? 'user@tembs.com';
  static String get currentUserName => currentUser?.fullName ?? supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Bourama Tembely';

  /// Initialise la session au démarrage de l'appli
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = prefs.getString(_currentSessionKey);
    if (sessionData != null) {
      try {
        final json = jsonDecode(sessionData);
        currentUserNotifier.value = AppUser.fromJson(json);
      } catch (_) {}
    }

    // Backup si Supabase a une session active
    if (currentUserNotifier.value == null && supabase.auth.currentSession != null) {
      final sUser = supabase.auth.currentUser;
      if (sUser != null) {
        currentUserNotifier.value = AppUser(
          id: sUser.id,
          email: sUser.email ?? '',
          fullName: sUser.userMetadata?['full_name'] ?? 'Utilisateur',
        );
      }
    }
  }

  /// Inscription : Crée le compte localement + tente Supabase et REDIRIGE DIRECTEMENT
  static Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    final prefs = await SharedPreferences.getInstance();
    final accountsRaw = prefs.getString(_registeredAccountsKey);
    List<dynamic> accounts = accountsRaw != null ? jsonDecode(accountsRaw) : [];

    // Vérifier si le compte existe déjà localement
    final exists = accounts.any((acc) => (acc['email'] as String).toLowerCase() == cleanEmail);
    if (exists) {
      throw 'Un compte existe déjà avec cette adresse email.';
    }

    // Tenter l'inscription Supabase si possible
    String userId = const Uuid().v4();
    try {
      final res = await supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'full_name': cleanName},
      );
      if (res.user != null) {
        userId = res.user!.id;
      }
    } catch (_) {
      // Ignorer l'erreur SMTP 500 de Supabase, nous créons le compte localement !
    }

    final newUser = AppUser(id: userId, email: cleanEmail, fullName: cleanName);

    // Enregistrer le compte dans les comptes locaux
    accounts.add({
      'id': userId,
      'email': cleanEmail,
      'full_name': cleanName,
      'password': password,
    });
    await prefs.setString(_registeredAccountsKey, jsonEncode(accounts));

    // Définir comme utilisateur actif (Connexion automatique et redirection immédiate)
    await prefs.setString(_currentSessionKey, jsonEncode(newUser.toJson()));
    currentUserNotifier.value = newUser;
  }

  /// Connexion par email + mot de passe
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Tenter la connexion Supabase d'abord
    try {
      final res = await supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
      if (res.user != null) {
        final user = AppUser(
          id: res.user!.id,
          email: res.user!.email ?? cleanEmail,
          fullName: res.user!.userMetadata?['full_name'] ?? 'Utilisateur',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_currentSessionKey, jsonEncode(user.toJson()));
        currentUserNotifier.value = user;
        return;
      }
    } catch (_) {
      // Si Supabase rejette ou n'est pas accessible, vérifier les comptes enregistrés
    }

    // 2. Vérifier les comptes enregistrés localement
    final prefs = await SharedPreferences.getInstance();
    final accountsRaw = prefs.getString(_registeredAccountsKey);
    if (accountsRaw != null) {
      final List<dynamic> accounts = jsonDecode(accountsRaw);
      final match = accounts.firstWhere(
        (acc) =>
            (acc['email'] as String).toLowerCase() == cleanEmail &&
            acc['password'] == password,
        orElse: () => null,
      );

      if (match != null) {
        final user = AppUser.fromJson(match);
        await prefs.setString(_currentSessionKey, jsonEncode(user.toJson()));
        currentUserNotifier.value = user;
        return;
      }
    }

    throw 'Email ou mot de passe incorrect.';
  }

  /// Déconnexion
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSessionKey);
    try {
      await supabase.auth.signOut();
    } catch (_) {}
    currentUserNotifier.value = null;
  }
}
