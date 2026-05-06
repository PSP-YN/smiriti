# Smriti

**Your second memory, on your phone.**

Smriti is an offline-first AI notebook for Android. Import PDFs, images, and audio — then ask questions and get grounded answers backed by citations from your own documents. Everything runs on-device. No data ever leaves your phone.

---

## Features

| Feature | Detail |
|---------|--------|
| **100% Offline** | All AI inference and processing happens on-device |
| **PDF & Text** | Full text extraction from multi-page PDFs |
| **Image OCR** | Extract text from photos using ML Kit (camera or gallery) |
| **Audio Import** | Index audio files for search (transcription via Whisper model) |
| **Conversational AI** | Ask natural language questions, get cited answers |
| **Semantic Search** | Vector-based search finds relevant content instantly |
| **App Lock** | Biometric / PIN protection enforced on every launch |
| **Dark Mode** | Follows system theme |

---

## Tech Stack

- **Framework:** Flutter (Dart 3.3+)
- **Database:** ObjectBox (vector store for embeddings)
- **LLM Runtime:** llama.cpp (GGUF models via FFI)
- **OCR:** Google ML Kit Text Recognition (offline)
- **Embedding:** all-MiniLM-L6-v2 via TFLite
- **PDF Parsing:** Syncfusion Flutter PDF
- **Security:** flutter_secure_storage, local_auth

---

## Getting Started

### Prerequisites

- Flutter SDK 3.19+
- Android Studio with Android SDK
- Android device / emulator (API 21+)

### Build & Run

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Production APK
flutter build apk --release

# Play Store bundle
flutter build appbundle --release

# Code quality check
flutter analyze
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete Play Store submission instructions.

---

## Project Structure

```
lib/
├── core/
│   ├── animations/       # AnimatedLogo, FadeAnimation, SlideAnimation
│   ├── constants/        # AppConstants (version, file types, keys)
│   ├── di/               # GetIt dependency injection
│   ├── services/         # LLM, Embedding, OCR, Audio, Security, Models
│   └── theme/            # Light + dark MaterialTheme
├── data/
│   ├── datasources/      # SharedPreferences + file I/O layer
│   ├── models/           # ObjectBox entity models (Document, Chunk)
│   ├── objectbox_store.dart
│   └── repositories/     # DocumentRepository implementation
├── domain/
│   ├── entities/         # Pure Dart domain models
│   ├── repositories/     # Abstract repository interfaces
│   └── services/         # RAGOrchestrator (retrieve → generate)
└── presentation/
    ├── bloc/             # DocumentBloc (events + states)
    ├── pages/            # All app screens
    └── widgets/          # Reusable UI components
```

---

## Privacy & Security

- All AI inference and document processing runs fully on-device
- No analytics, telemetry, or cloud sync
- Documents stored in app-private scoped storage
- Encryption: AES-GCM via Android EncryptedSharedPreferences
- Biometric lock using Android Biometric API
- Network: HTTPS-only, used only for optional model downloads
- `allowBackup=false` prevents ADB backup of sensitive data

---

## AI Models (Optional Downloads)

| Model | Use | Size |
|-------|-----|------|
| Gemma 2B Q4 | AI chat answers | ~1.3 GB |
| Llama 3.2 1B Q4 | Chat (low-RAM) | ~700 MB |
| Phi-3 Mini Q4 | Advanced reasoning | ~1.9 GB |
| all-MiniLM-L6-v2 | Semantic search | ~25 MB |
| Whisper Tiny | Audio transcription | ~75 MB |

Download from inside the app: **Settings → AI Models**

---

## License

MIT License — free for personal and commercial use.

## Acknowledgments

- [llama.cpp](https://github.com/ggerganov/llama.cpp) — on-device LLM inference
- [ObjectBox](https://objectbox.io/) — high-performance vector database
- [Google ML Kit](https://developers.google.com/ml-kit) — offline OCR
- [Syncfusion](https://www.syncfusion.com/) — PDF processing
- [Hugging Face](https://huggingface.co/) — model hosting
