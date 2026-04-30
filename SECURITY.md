# Security & Privacy Documentation

## Overview

Smriti is designed with **privacy-by-design** principles. All data processing happens on-device, and no user data ever leaves the phone.

## Data Storage Security

### Document Encryption at Rest

- Documents are stored in the app's private directory (Android: `/data/data/com.smriti.app/files/`)
- Optional AES-256 encryption using `flutter_secure_storage` keys
- Encryption keys are stored in the device's secure hardware (Keychain on iOS, Keystore on Android)

### Vector Database Security

- ObjectBox database stored in app-private directory
- Vector embeddings are derived from user documents but contain no recoverable document content
- Database is inaccessible to other apps (sandboxed)

### Secure Storage Implementation

```dart
// All sensitive data uses flutter_secure_storage
final _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  ),
);
```

## Authentication

### Biometric Authentication

- Optional fingerprint/face unlock using `local_auth`
- Falls back to device PIN/password if biometrics unavailable
- Can be enabled/disabled in Settings

### App Lock

- Locks app on backgrounding when enabled
- Requires authentication on cold start

## Network Security

### Offline-First Design

- No internet connection required for core functionality
- No cloud APIs used for document processing
- Model downloads (when implemented) use HTTPS with certificate pinning

### Data Never Leaves Device

| Operation | Location | Notes |
|-----------|----------|-------|
| PDF parsing | On-device | Syncfusion Flutter PDF |
| Text extraction | On-device | Local algorithms |
| Embeddings | On-device | TFLite model |
| Vector search | On-device | ObjectBox |
| LLM inference | On-device | llama.cpp (Week 3) |
| OCR | On-device | Google ML Kit |

## Model Security

### Model Integrity

- All models (embeddings, LLM) are verified with SHA-256 checksums
- Models are downloaded over HTTPS
- No model data sent to external servers

### Model Storage

```dart
// Models stored in app-private directory
final modelPath = '${appDir.path}/models/$modelName';
```

## Privacy Guarantees

### No Data Collection

- No analytics
- No telemetry
- No crash reporting (unless user explicitly enables)
- No advertising identifiers

### Document Privacy

- Documents never uploaded to cloud
- No OCR text sent to Google servers (ML Kit runs locally)
- No LLM queries sent to external APIs

## Security Best Practices

### For Developers

1. **Never log sensitive data**
   ```dart
   // BAD
   print('User document: $documentContent');
   
   // GOOD
   debugPrint('Document processed successfully');
   ```

2. **Use secure random for encryption**
   ```dart
   final key = SecureRandom().nextBytes(32);
   ```

3. **Validate file types before processing**
   ```dart
   if (!AppConstants.supportedExtensions.contains(extension)) {
     throw UnsupportedError('File type not supported');
   }
   ```

4. **Sanitize user input**
   ```dart
   final sanitized = query.replaceAll(RegExp(r'[<>\"\']'), '');
   ```

### For Users

1. **Enable biometric lock** in Settings
2. **Use strong device PIN/password**
3. **Download models only over trusted Wi-Fi**
4. **Regularly backup important documents** (export feature coming in Week 4)

## Security Checklist for Deployment

- [ ] ProGuard/R8 obfuscation enabled
- [ ] Debug logging disabled in release
- [ ] Network security config validated
- [ ] Biometric auth tested
- [ ] Encryption at rest verified
- [ ] App sandbox isolation confirmed
- [ ] Model integrity checksums implemented
- [ ] Privacy policy drafted

## Threat Model

| Threat | Mitigation |
|--------|------------|
| Device theft | Biometric + encryption at rest |
| Malicious app access | Android sandbox + app-private storage |
| Network interception | Offline-first design |
| Root/jailbreak | Keychain/Keystore hardware security |
| Memory dump | Sensitive data cleared after use |

## Compliance

### GDPR (EU Users)

- Right to erasure: Clear All Data in Settings
- Data minimization: Only store what user provides
- Privacy by design: All processing on-device

### CCPA (California Users)

- No personal information sold
- No third-party data sharing

### Indian Data Protection

- No data stored outside India
- No cross-border data transfer

## Reporting Security Issues

If you discover a security vulnerability, please:
1. Do not open a public issue
2. Email security concerns to [security@smriti.app]
3. Allow 30 days for response before public disclosure

## Security Updates

| Version | Security Changes |
|---------|-----------------|
| 1.0.0 | Initial security implementation |
| TBD | Certificate pinning for model downloads |
| TBD | Document export encryption |

---

**Last Updated**: Week 2 Build  
**Review Cycle**: Every release
