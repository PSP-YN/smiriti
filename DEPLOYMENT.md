# Smriti — Deployment Guide

**Version:** 1.0.0 (Build 1)  
**Platform:** Android 5.0+ (API 21+)  
**Architecture:** Flutter + ObjectBox + ML Kit + TFLite

---

## Build Outputs

| Artifact | Path | Size |
|----------|------|------|
| APK (sideload / test) | `build/app/outputs/flutter-apk/app-release.apk` | ~50 MB |
| AAB (Play Store) | `build/app/outputs/bundle/release/app-release.aab` | ~58 MB |

---

## Quick Install (Sideload)

```bash
# Connect Android phone with USB debugging enabled
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Requirements:** Android 5.0+ (API 21), 50–4000 MB free storage.

---

## Google Play Store Submission

### Step 1 — Create Release Keystore

> Do this once. Store the keystore file safely — it cannot be recovered.

```bash
keytool -genkey -v \
  -keystore ~/smriti-release.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias smriti
```

### Step 2 — Configure Signing

In `android/app/build.gradle`, add inside `android {}`:

```groovy
signingConfigs {
    release {
        keyAlias      System.getenv("KEY_ALIAS")        ?: "smriti"
        keyPassword   System.getenv("KEY_PASSWORD")     ?: ""
        storeFile     file(System.getenv("KEYSTORE_PATH") ?: "~/smriti-release.jks")
        storePassword System.getenv("STORE_PASSWORD")   ?: ""
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### Step 3 — Build Signed AAB

```bash
export KEY_ALIAS=smriti
export KEY_PASSWORD=<your-key-password>
export KEYSTORE_PATH=~/smriti-release.jks
export STORE_PASSWORD=<your-store-password>

flutter build appbundle --release
```

### Step 4 — Play Console Checklist

- [ ] Upload `app-release.aab` to **Production** or **Internal Testing** track
- [ ] Screenshots: phone (min 2), 7-inch tablet (optional)
- [ ] Short description (80 chars): *"Offline AI notebook — ask questions about your PDFs and documents."*
- [ ] Content rating: **Everyone** (no user content, no violence)
- [ ] **Data safety form:** select *"No data collected"* — app is fully offline
- [ ] Privacy policy URL — host the text from the in-app Privacy Policy page
- [ ] Category: **Productivity**

---

## Rebuild Commands

```bash
# Clean rebuild (if errors after code changes)
flutter clean && flutter pub get && flutter build apk --release

# Debug run (hot reload)
flutter run

# Release APK
flutter build apk --release

# Release AAB (Play Store)
flutter build appbundle --release

# Code analysis (should show 0 errors, 0 warnings)
flutter analyze
```

---

## Feature Status

### Works Fully (No Downloads Required)

| Feature | Detail |
|---------|--------|
| PDF import & text extraction | Syncfusion PDF |
| Image OCR (camera + gallery) | ML Kit, fully offline |
| Document management | Add, delete, list |
| App Lock + Biometrics | Enforced on every cold start |
| Dark / Light mode | Follows system preference |
| Privacy Policy page | Full in-app page |
| Clear All Data | Wipes ObjectBox + files + models |
| Storage usage display | Real disk size shown |
| Copy summary to clipboard | Working |

### Requires First-Time Model Download

| Feature | Model | Size |
|---------|-------|------|
| AI chat answers | Gemma 2B Q4 or Llama 3.2 1B Q4 | 800 MB – 1.4 GB |
| Semantic search | all-MiniLM-L6-v2 (embedding) | ~25 MB |
| Audio transcription | Whisper Tiny | ~75 MB |

Download from: **Settings → AI Models → Download**

---

## Security Summary

| Control | Implementation |
|---------|---------------|
| Data storage | Android EncryptedSharedPreferences (AES-GCM) |
| Keystore | RSA-OAEP-SHA-256 |
| App lock | Biometric gate enforced on every cold start |
| Biometric | `local_auth` with PIN/pattern fallback |
| Password hashing | SHA-256 + 16-byte random salt |
| Network | HTTPS-only via `network_security_config.xml` |
| Backup | `allowBackup=false` — blocks ADB backup |
| File access | Scoped storage (no MANAGE_EXTERNAL_STORAGE) |

---

## Architecture

```
lib/
├── core/
│   ├── animations/       # Reusable animation widgets
│   ├── constants/        # AppConstants (version, keys, extensions)
│   ├── di/               # GetIt dependency injection
│   ├── services/         # App-level services (auth, models, OCR, LLM)
│   └── theme/            # Light + dark MaterialTheme
├── data/
│   ├── datasources/      # SharedPreferences + file I/O
│   ├── models/           # ObjectBox entity models
│   ├── objectbox_store.dart
│   └── repositories/     # DocumentRepository implementation
├── domain/
│   ├── entities/         # Pure Dart domain models
│   ├── repositories/     # Abstract interfaces
│   └── services/         # RAG orchestrator (retrieve + generate)
└── presentation/
    ├── bloc/             # DocumentBloc (events, states)
    ├── pages/            # All screens
    └── widgets/          # Reusable UI components
```

---

## Environment

| Tool | Version |
|------|---------|
| Flutter | 3.19+ |
| Dart | 3.3+ |
| Android minSdk | 21 (Android 5.0) |
| Android targetSdk | 34 (Android 14) |
| Build tool | Gradle + R8 minification |
