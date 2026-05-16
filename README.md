# Amethyst

Flutter app for water station accounting and management. The app uses **Firebase** only (Authentication, Cloud Firestore, Firebase Storage).

## Prerequisites

- Flutter SDK 3.11+
- A Firebase project with Email/Password auth, Firestore, and Storage enabled

## Firebase setup

1. Install FlutterFire CLI and configure the project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` with your project credentials.

2. Deploy security rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

3. Create the first super admin in Firebase Console:
   - Authentication → add a user (email + password)
   - Firestore → `users/{uid}` with fields: `fullName`, `email`, `role: super_admin`, `isActive: true`, `createdAt`, `updatedAt`

## Run the app

```bash
flutter pub get
flutter run
```

## Web deploy (Firebase Hosting)

```bash
flutter build web --release
firebase deploy --only hosting
```

## Collections

Firestore collections: `users`, `products`, `vehicles`, `vehicle_loads`, `station_sales`, `station_debt_entries`, `vehicle_sales`, `expenses`, `stock_movements`.

See `firestore.rules` and `firestore.indexes.json` in the project root.
