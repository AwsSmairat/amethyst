# Amethyst

تطبيق Flutter لإدارة ومحاسبة محطة مياه. يعمل على **Firebase** (Authentication، Cloud Firestore، Storage، Cloud Functions).

**المشروع الحالي:** `amethyst-3328a`

## المتطلبات

- Flutter SDK 3.11+
- Firebase CLI (`npm i -g firebase-tools`)
- مشروع Firebase مع: Email/Password Auth، Firestore، Storage (اختياري للصور)

## إعداد Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=amethyst-3328a
firebase use amethyst-3328a
firebase deploy --only firestore:rules,firestore:indexes,functions
```

فعّل **Storage** من [Firebase Console](https://console.firebase.google.com/project/amethyst-3328a/storage) ثم:

```bash
firebase deploy --only storage
```

## الحسابات الافتراضية (بعد bootstrap)

| البريد | الاسم | الدور |
|--------|-------|-------|
| `sohaib@super.com` | صهيب | سوبر أدمن |
| `admin@admin.com` | مسؤول المحطة | أدمن |
| `driver@driver.com` | سائق بينقو | سائق |
| `driver2@driver.com` | سائق الباص | سائق |

المركبات: **بينقو** (سائق ١)، **الباص** (سائق ٢).

## Bootstrap (بيانات أولية)

دوال HTTP محمية بسرّ. الافتراضي: `amethyst-3328a-setup` — غيّره عبر `BOOTSTRAP_SECRET` في Functions.

```bash
SECRET=amethyst-3328a-setup

# ملفات users في Firestore
curl -X POST -H "x-bootstrap-secret: $SECRET" \
  https://us-central1-amethyst-3328a.cloudfunctions.net/bootstrapUserProfiles

# منتجات + مخزون + مركبات
curl -X POST -H "x-bootstrap-secret: $SECRET" \
  https://us-central1-amethyst-3328a.cloudfunctions.net/bootstrapAppCatalog

# الاثنان معاً
curl -X POST -H "x-bootstrap-secret: $SECRET" \
  "https://us-central1-amethyst-3328a.cloudfunctions.net/bootstrapUserProfiles?all=1"
```

## تشغيل التطبيق

```bash
flutter pub get
flutter run
```

## بناء APK

```bash
flutter build apk --release
# الملف: build/app/outputs/flutter-apk/app-release.apk
```

## نشر الويب

```bash
flutter build web --release
firebase deploy --only hosting
```

## Collections

`users`, `products`, `vehicles`, `vehicle_loads`, `station_sales`, `station_debt_entries`, `vehicle_sales`, `expenses`, `stock_movements`, `staff_notes`, `audit_logs`

القواعد: `firestore.rules` · الفهارس: `firestore.indexes.json`
