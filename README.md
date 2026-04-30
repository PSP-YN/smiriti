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

**Build**: ✅ **WEEKS 1-9 COMPLETE - PRODUCTION READY**  
**Status**: Modern logo, animations, optimized, deployment ready  
**Last Updated**: Week 9 (Final Polish + Production Optimization)  
**Analysis**: 0 errors, 0 warnings ✅

## Development Roadmap

### Week 1: App Shell + PDF Extraction

- [x] Flutter project setup
- [x] Clean architecture structure
- [x] App shell with notebook-themed UI
- [x] File picker integration
- [x] PDF text extraction (syncfusion_flutter_pdf)
- [x] Document listing and management

### Week 2: Chunking + Embeddings + Vector DB

- [x] Semantic chunking (~500 tokens)
- [x] ObjectBox integration with vector search
- [x] all-MiniLM-L6-v2 embedding model integration
- [x] Batch embedding generation
- [x] Document encryption at rest
- [x] Biometric authentication
- [x] Security hardening
- [x] Settings page with model manager

### Week 3: LLM Integration ✅

- [x] llama.cpp FFI bindings setup
- [x] Model download manager with progress tracking
- [x] Multiple model support (Gemma 2B, Llama 3.2 1B, Phi-3 Mini)
- [x] Token streaming to UI
- [x] Full RAG pipeline with LLM
- [x] Native Android integration (CMake, JNI, Kotlin bridge)

### Week 4: Multi-Document + Citations + Summarization ✅

- [x] Cross-document retrieval with filtering
- [x] Enhanced citations with source content preview
- [x] Clickable source links in chat
- [x] Summarization page (Concise, Detailed, Bullet Points)
- [x] Document-level summarize action
- [x] Multi-select document filter UI

### Week 5: OCR + Audio + Multi-Script ✅

- [x] Google ML Kit OCR for images (PNG, JPG, WebP, BMP, GIF)
- [x] whisper.cpp for audio transcription (MP3, WAV, M4A, AAC, OGG, FLAC)
- [x] Multi-script support (Latin, Devanagari, Japanese, Korean, Chinese)
- [x] Camera capture for instant OCR
- [x] Image preprocessing (grayscale, contrast, resize)
- [x] Automatic script detection
- [x] Timestamped transcription output
- [x] Audio transcription progress streaming

### Week 6: Polish + Optimization ✅

- [x] Comprehensive error handling system
- [x] Cold start optimization with splash screen
- [x] App initialization service
- [x] Error boundary widget
- [x] Graceful degradation

### Week 7: Beta + Launch ✅

- [x] All 61 analysis issues fixed
- [x] Production build configuration
- [x] Error resilience testing
- [x] Documentation complete

### Week 8: Final UI/UX Polish ✅

- [x] Modern SVG logo design
- [x] Comprehensive animation system
- [x] Animated splash screen
- [x] Page transition animations
- [x] Button feedback animations
- [x] Staggered list animations
- [x] Shimmer loading effects

### Week 9: Production Optimization ✅

- [x] Performance tuning (60fps animations)
- [x] Memory optimization
- [x] Asset configuration
- [x] Font integration (PlayfairDisplay)
- [x] Final error checking
- [x] **Ready for Play Store submission**
- [ ] Demo video

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

This is a club project. See the [workflow documentation](.windsurf/workflows/smriti.md) for detailed development steps.

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Acknowledgments

- [llama.cpp](https://github.com/ggerganov/llama.cpp) for on-device LLM inference
- [Google Gemma](https://ai.google.dev/gemma) for the base language model
- [ObjectBox](https://objectbox.io/) for high-performance vector storage
- [Syncfusion](https://www.syncfusion.com/) for PDF processing
