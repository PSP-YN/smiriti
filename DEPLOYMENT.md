# Deployment Guide

## Prerequisites

- Flutter SDK 3.11.5 or later
- Android SDK (API 21+)
- Android Studio / Xcode
- Signing keystore (for release)

## Development Environment Setup

### 1. Install Flutter

```bash
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

### 2. Install Dependencies

```bash
cd smriti
flutter pub get
```

### 3. Initialize ObjectBox

```bash
dart run build_runner build
```

## Build Configurations

### Debug Build (Development)

```bash
flutter build apk --debug
```

**Output**: `build/app/outputs/flutter-apk/app-debug.apk`

### Profile Build (Performance Testing)

```bash
flutter build apk --profile
```

### Release Build (Production)

```bash
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

## Android Signing

### Create Keystore

```bash
keytool -genkey -v \
  -keystore smriti-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias smriti
```

### Configure Signing

Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=smriti
storeFile=../smriti-release-key.jks
```

Update `android/app/build.gradle`:

```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

## App Bundle (Play Store)

```bash
flutter build appbundle --release
```

**Output**: `build/app/outputs/bundle/release/app-release.aab`

## Play Store Submission

### 1. Prepare Assets

- **App Icon**: 512x512 PNG
- **Feature Graphic**: 1024x500 PNG
- **Screenshots**: Phone (1080x1920) x 8, Tablet (2732x2048) x 8
- **Privacy Policy**: Link to hosted policy

### 2. App Information

| Field | Value |
|-------|-------|
| App Name | Smriti |
| Short Description | Offline AI notebook for your documents |
| Full Description | (See below) |
| Category | Education / Productivity |
| Content Rating | Everyone |

**Full Description**:
```
Smriti - Your second memory, on your phone.

Turn your textbooks, notes, and documents into a searchable knowledge base that works completely offline.

KEY FEATURES:
✓ 100% Offline - No internet required
✓ Privacy First - Your data never leaves your device
✓ AI-Powered Search - Ask questions in natural language
✓ Multi-Format - PDF, TXT, images, audio
✓ Citations - See exactly where answers come from

PERFECT FOR:
• Students preparing for exams
• Researchers organizing papers
• Professionals managing documents
• Anyone who values privacy

HOW IT WORKS:
1. Add your documents
2. Smriti indexes them with AI
3. Ask questions naturally
4. Get answers with sources

No accounts. No subscriptions. No data collection.

TECHNOLOGY:
• On-device AI (Gemma 2B)
• Semantic search with vector embeddings
• Local LLM inference
• Military-grade encryption

Download once, use forever - even on airplane mode.
```

### 3. Content Rating

- Violence: None
- Sexual Content: None
- Language: None
- Controlled Substances: None

### 4. Privacy Policy

Required text:
```
Smriti Privacy Policy

Last Updated: [Date]

Smriti does not collect, store, or transmit any personal data. 
All document processing happens on your device.

Data Storage:
- Documents are stored locally on your device
- AI models run entirely offline
- No cloud servers are used
- No analytics or tracking

Permissions:
- Storage: To read your documents
- Biometric: For optional app lock

Contact: privacy@smriti.app
```

### 5. App Review Checklist

- [ ] App icon meets guidelines
- [ ] No copyrighted material in screenshots
- [ ] Privacy policy URL valid
- [ ] Contact email provided
- [ ] Tested on target devices (Android 8+)
- [ ] App size under 200MB (APK) / 150MB (base)

## Release Checklist

### Pre-Build

- [ ] Version updated in `pubspec.yaml`
- [ ] Changelog updated
- [ ] Security audit complete
- [ ] All tests passing

### Build

- [ ] Release APK builds successfully
- [ ] App bundle generated
- [ ] Signed with release key
- [ ] ProGuard mapping saved

### Testing

- [ ] Fresh install test
- [ ] Document upload test
- [ ] Chat/query test
- [ ] Offline mode test
- [ ] Biometric auth test
- [ ] Low-memory device test

### Submission

- [ ] Screenshots uploaded
- [ ] Store listing complete
- [ ] Privacy policy linked
- [ ] Content rating complete
- [ ] Pricing set (Free)
- [ ] Countries selected

## CI/CD Setup (GitHub Actions)

```yaml
# .github/workflows/release.yml
name: Build Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.11.5'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Build AppBundle
        run: flutter build appbundle --release
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: release
          path: |
            build/app/outputs/flutter-apk/app-release.apk
            build/app/outputs/bundle/release/app-release.aab
```

## Troubleshooting

### Build Errors

**Error**: `Duplicate class found`
**Fix**: Run `flutter clean && flutter pub get`

**Error**: `Keystore file not found`
**Fix**: Verify `key.properties` path is correct

**Error**: `ObjectBox not generated`
**Fix**: Run `dart run build_runner build --delete-conflicting-outputs`

### Size Issues

If APK > 200MB:
```bash
flutter build apk --release --split-per-abi
```

## Post-Launch

### Monitoring

- Crashlytics integration (optional, opt-in)
- Google Play Console analytics
- User feedback collection

### Updates

- Semantic versioning (MAJOR.MINOR.PATCH)
- Release notes in changelog
- Gradual rollout (staged releases)

---

**Current Version**: 1.0.0 (Week 2)  
**Target**: Google Play Store  
**Timeline**: Week 9 (June 30)
