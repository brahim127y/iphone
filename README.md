# Ma Boutique — App de gestion de boutique (Flutter)

Application mobile (Android + iPhone) en Flutter, avec compte utilisateur et synchronisation cloud via Supabase.

## Fonctionnalités
- Authentification par email/mot de passe
- Catégories de produits
- Produits : nom, prix, quantité en stock, image optionnelle, date d'enregistrement
- Ventes : panier multi-produits, client optionnel, mode de paiement, décrémentation automatique du stock
- Clients : fiche simple (nom, téléphone, adresse, notes)
- Tableau de bord : ventes du jour/mois, alerte stock faible
- Export PDF par mois ou par année (détail des ventes + top produits), généré et partagé directement depuis le téléphone

## Installation locale

1. Installe le [SDK Flutter](https://docs.flutter.dev/get-started/install) si ce n'est pas déjà fait.
2. Récupère les dépendances :
   ```bash
   flutter pub get
   ```
3. Copie `.env.example` en `.env` et renseigne tes clés Supabase (voir guide d'hébergement plus bas) :
   ```bash
   cp .env.example .env
   ```
4. Lance l'appli sur un appareil/émulateur connecté :
   ```bash
   flutter run
   ```

## Structure du projet
```
lib/
  main.dart                point d'entrée, initialise Supabase
  config/theme.dart        couleurs, thème sombre, formatage FCFA
  models/models.dart       Category, Product, Customer, Sale, CartLine
  screens/
    auth_gate.dart          redirige vers login ou l'appli selon la session
    auth/                   écrans connexion / inscription
    home/                   accueil, produits, ventes, clients, export
supabase/
  schema.sql                schéma de base de données + sécurité (RLS) à exécuter sur Supabase
```

## Hébergement du backend (Supabase)
Le backend est 100% identique à un projet React Native : crée un projet sur [supabase.com](https://supabase.com), exécute `supabase/schema.sql` dans le SQL Editor, crée un bucket de stockage public nommé `product-images`, puis récupère l'URL et la clé "anon public" du projet (Project Settings → API) pour les mettre dans `.env`.

## Build pour publication (Android/iPhone)
```bash
flutter build apk --release        # Android (fichier .apk)
flutter build appbundle --release  # Android (Play Store)
flutter build ios --release        # iPhone (nécessite un Mac + Xcode)
```

## Compilation Linux (bureau)
Pratique pour développer/tester rapidement sans émulateur Android.

```bash
flutter config --enable-linux-desktop
flutter create --platforms=linux .
# Dépendances système (Ubuntu/Debian) :
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev
flutter run -d linux
```

⚠️ Le package `image_picker` n'a pas d'implémentation Linux desktop. Sur Linux, l'écran d'ajout de produit propose donc de **coller une URL d'image** au lieu de choisir un fichier local — le comportement reste inchangé sur Android/iPhone (sélection depuis la galerie).

Pour un build final :
```bash
flutter build linux --release
```
