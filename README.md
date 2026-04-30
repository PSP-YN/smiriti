# Smriti

**Your second memory, on your phone.**

Smriti is a mobile application that turns any collection of personal documents — PDFs, lecture notes, images, audio recordings, textbooks — into a queryable, conversational knowledge base. Everything runs on-device. No internet required after setup. No data ever leaves the phone.

## Features

- **Privacy by Design**: All processing happens locally. Your sensitive documents never touch a server.
- **Works Offline**: No internet required. Perfect for classrooms, remote areas, flights, and distraction-free study.
- **Multi-format Support**: PDF, TXT, DOCX, images (OCR), audio (transcription)
- **Conversational RAG**: Ask natural-language questions, get grounded answers with citations
- **Fast Retrieval**: Vector-based semantic search finds relevant content in milliseconds

## Tech Stack

- **Framework**: Flutter (cross-platform)
- **LLM Runtime**: llama.cpp (via FFI bindings)
- **LLM Models**:
  - Gemma 2B Q4 (~1.3GB) - default
  - Llama 3.2 1B Q4 (~700MB) - fallback for low-RAM devices
- **Embedding**: all-MiniLM-L6-v2 quantized (~25MB)
- **Vector Database**: ObjectBox with built-in vector search
- **Document Parsing**:
  - PDF: syncfusion_flutter_pdf
  - OCR: Google ML Kit Text Recognition (5 scripts)
  - Audio: whisper.cpp (multilingual transcription)
  - Camera: image_picker
  - Image Processing: image (Dart)

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── di/
│   ├── services/         # LLM, Embeddings, Security
│   └── theme/
├── data/
│   ├── datasources/
│   ├── models/           # ObjectBox entities
│   ├── objectbox_store.dart
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── services/         # RAG Orchestrator
└── presentation/
    ├── bloc/
    ├── pages/            # Home, Chat, Summarize, Settings, Model Download
    └── widgets/
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / Xcode
- Android SDK for Android builds
- 8GB+ RAM development machine

### Installation

1. Clone the repository:

```bash
git clone https://github.com/your-org/smriti.git
cd smriti
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

### Building for Production

**Android:**

```bash
# Debug
flutter run

# Release APK (split by architecture)
flutter build apk --release --split-per-abi

# Play Store bundle
flutter build appbundle --release

# Analyze
flutter analyze
```

## Current Status

**Build**: ✅ **PRODUCTION READY**  
**Status**: Modern UI, fully optimized, deployment ready.  
**Analysis**: 0 errors, 0 warnings ✅

## Performance Targets

| Operation                      | Target          |
| ------------------------------ | --------------- |
| First PDF embedding (50 pages) | ~30 seconds     |
| RAG retrieval                  | < 1 second      |
| LLM token generation           | 5-10 tokens/sec |
| End-to-end answer              | 10-30 seconds   |
| Cold start                     | 3-5 seconds     |

## Privacy & Security

- All AI inference runs on-device
- Documents stored in app-private storage
- No network calls for AI operations
- No analytics or telemetry
- Optional: document encryption at rest

## Contributing

We welcome contributions from the community. Please submit a pull request or open an issue to discuss proposed changes.

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Acknowledgments

- [llama.cpp](https://github.com/ggerganov/llama.cpp) for on-device LLM inference
- [Google Gemma](https://ai.google.dev/gemma) for the base language model
- [ObjectBox](https://objectbox.io/) for high-performance vector storage
- [Syncfusion](https://www.syncfusion.com/) for PDF processing
