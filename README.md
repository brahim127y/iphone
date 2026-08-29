# Tembs — App de gestion de boutique (Flutter - 100% Hors-ligne)

Application mobile et desktop (Android, iOS, Linux) en Flutter avec base de données locale intégrée (SQLite).
Fonctionne intégralement sans connexion internet et sans authentification.

## Fonctionnalités
- **Base de données intégrée (SQLite / sqflite)** : stockage 100% local, instantané et sécurisé sur le téléphone
- **Catégories de produits** : organisation et filtrage facile
- **Produits** : nom, prix, quantité en stock, image, date d'enregistrement
- **Ventes** : panier multi-produits, sélection du client, choix du mode de paiement, décrémentation automatique du stock
- **Gestion des clients** : fiches avec coordonnées et notes
- **Tableau de bord** : chiffre d'affaires du jour/mois, nombre de ventes, alerte stock faible
- **Exportation PDF** : rapports mensuels/annuels avec graphiques et top produits, partageables directement

## Lancement rapide

1. Installe le [SDK Flutter](https://docs.flutter.dev/get-started/install) si ce n'est pas déjà fait.
2. Récupère les dépendances :
   ```bash
   flutter pub get
   ```
3. Lance l'application :
   ```bash
   flutter run
   ```

## Structure du projet
```
lib/
  main.dart                point d'entrée, initialise SQLite (DatabaseService)
  config/theme.dart        thème premium, couleurs, formatage FCFA
  models/models.dart       Category, Product, Customer, Sale, CartLine
  services/
    database_service.dart  gestionnaire SQLite locale (sqflite)
  screens/
    home/                   accueil, produits, ventes, clients, export, profil
```

## Build pour publication (Android/iPhone)
```bash
flutter build apk --release        # Android (fichier .apk)
flutter build appbundle --release  # Android (Play Store)
flutter build ios --release        # iPhone (Mac + Xcode requis)
```

## Build Linux (Desktop)
```bash
flutter run -d linux
flutter build linux --release
```
