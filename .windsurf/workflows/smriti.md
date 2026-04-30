---
description: Build Smriti - an offline AI notebook app for querying personal documents
---

# Smriti Workflow

Complete development workflow for building Smriti, a Flutter-based offline RAG app that turns personal documents into a queryable knowledge base using on-device LLM inference.

## Prerequisites

- Flutter SDK (latest stable)
- Android Studio / Xcode
- 8GB+ RAM development machine
- Test device: Android phone with 6GB+ RAM (Snapdragon 7-series or equivalent)

## Week 1: App Shell + PDF Extraction

### Project Setup
1. Create Flutter project: `flutter create smriti`
2. Add dependencies to `pubspec.yaml`:
   - `file_picker: ^6.1.1`
   - `syncfusion_flutter_pdf: ^24.1.41`
   - `objectbox: ^2.5.0`
   - `objectbox_flutter_libs: ^2.5.0`
   - `flutter_bloc: ^8.1.3` (state management)
   - `get_it: ^7.6.4` (DI)
3. Set up project structure:
   ```
   lib/
   ├── core/           # DI, utils, constants
   ├── data/           # Repositories, local DB
   ├── domain/         # Entities, use cases
   ├── presentation/   # UI, blocs
   └── main.dart
   ```

### UI Implementation
4. Create notebook-style home screen with document list
5. Implement file picker UI supporting PDF, TXT, DOCX
6. Build chat interface with message bubbles
7. Add document viewer with page navigation

### PDF Extraction
8. Integrate `syncfusion_flutter_pdf` for text extraction
9. Create document ingestion service:
   - PDF → text extraction
   - Store raw text with metadata (filename, page count, timestamp)
10. Build end-to-end test: pick PDF → extract → display text

### Checkpoint
- [ ] File picker working on Android
- [ ] PDF text extraction functional
- [ ] Basic UI scaffold complete

## Week 2: Chunking + Embeddings + Vector DB

### Chunking Strategy
1. Implement semantic chunking:
   - Target: ~500 tokens per chunk
   - Respect paragraph boundaries
   - Metadata: source doc, page number, position
2. Add overlap (50-100 tokens) for context continuity

### ObjectBox Setup
3. Define entities:
   ```dart
   @Entity()
   class DocumentChunk {
     @Id()
     int id = 0;
     String documentId;
     String content;
     int pageNumber;
     List<double> embedding; // 384-dim for MiniLM
   }
   ```
4. Configure ObjectBox with vector search capability

### Embedding Model
5. Add `tflite_flutter` for running quantized models
6. Download `all-MiniLM-L6-v2` (quantized, ~25MB)
7. Implement embedding generation:
   - Input: text chunk
   - Output: 384-dimensional vector
8. Create batch processing for multiple chunks

### Integration
9. Full pipeline: Document → Chunks → Embeddings → Vector DB
10. Manual verification: query by vector similarity

### Checkpoint
- [ ] Chunking working with proper metadata
- [ ] Embeddings generated locally
- [ ] Vector search returning relevant chunks

## Week 3: LLM Integration

### llama.cpp Setup
1. Add `llama_cpp_dart` or FFI bindings for llama.cpp
2. Create model download manager:
   - Gemma 2B Q4 (~1.3GB)
   - Download on first launch (Wi-Fi only)
   - Progress indicator UI
3. Implement model loading with memory management

### Inference Pipeline
4. Build prompt template for RAG:
   ```
   Context: {retrieved_chunks}
   Question: {user_query}
   Answer based on the context above:
   ```
5. Implement token streaming to UI
6. Add "thinking" state indicator

### Basic Q&A
7. End-to-end: Query → Retrieve chunks → LLM → Answer
8. Single document support working
9. Test on target device, measure tokens/sec

### Checkpoint
- [ ] Model downloads and loads successfully
- [ ] Token streaming functional
- [ ] Basic RAG working end-to-end

## Week 4: Multi-Document + Citations + Summarization

### Multi-Document Support
1. Extend retrieval across all indexed documents
2. Add document filtering (search within specific docs)
3. Implement relevance scoring across corpus

### Citations
4. Modify prompt to request citations
5. Parse LLM output for source references
6. UI: Clickable citations linking to source pages
7. Show source chunks used for answer

### Summarization Mode
8. Add "Summarize" option in UI
9. Prompt template for summarization:
   ```
   Summarize the following document. Key points:
   {document_content}
   ```
10. Full-document chunk retrieval for summaries

### Checkpoint
- [ ] Multi-document queries working
- [ ] Citations clickable and accurate
- [ ] Summarization functional

## Week 5: OCR + Audio Transcription

### OCR (ML Kit)
1. Add `google_mlkit_text_recognition: ^0.11.0`
2. Implement image picker for photos
3. Text recognition flow:
   - Image → ML Kit OCR → Text → Chunk → Embed
4. Support Indian scripts (Devanagari, etc.)

### Audio (whisper.cpp)
5. Add audio file picker
6. Integrate whisper.cpp bindings:
   - tiny model (~40MB) for faster inference
   - base model (~80MB) for better accuracy
7. Transcription pipeline:
   - Audio → whisper.cpp → Text → Chunk → Embed
8. Show transcription progress

### Checkpoint
- [ ] OCR extracting text from images
- [ ] Audio transcription working
- [ ] Both feeding into chunking pipeline

## Week 6: Polish + Model Manager + Optimization

### Model Download Manager
1. Build settings screen
2. Model management:
   - Download Gemma 2B (default)
   - Fallback: Llama 3.2 1B for low-RAM devices
   - Delete / redownload options
3. Wi-Fi only download with user confirmation

### Cold Start Optimization
4. Pre-load model on app launch (if sufficient RAM)
5. Add splash screen with loading state
6. Optimize chunk retrieval speed

### UI Polish
7. Notebook-themed design:
   - Paper-like backgrounds
   - Handwriting-style fonts for headers
   - Smooth animations
8. Dark mode support
9. Error handling with user-friendly messages

### Checkpoint
- [ ] Model manager functional
- [ ] Cold start under 5 seconds
- [ ] UI polished and responsive

## Week 7: Beta Testing + Performance Profiling

### Closed Beta
1. Build release APK
2. Distribute to 10-15 test users (college students)
3. Create feedback form for:
   - Query accuracy
   - Answer relevance
   - Performance on their device
   - UI/UX issues

### Performance Profiling
4. Add logging for key metrics:
   - Embedding time per chunk
   - Retrieval latency
   - LLM tokens/second
   - Memory usage
5. Test on multiple devices:
   - 8GB RAM (flagship)
   - 6GB RAM (mid-range)
   - 4GB RAM (low-end - fallback model)

### Analytics (Local)
6. Store performance data locally
7. Export logs for analysis

### Checkpoint
- [ ] Beta feedback collected
- [ ] Performance data on 3+ device tiers
- [ ] Critical bugs identified

## Week 8: Bug Fixes + Low-RAM Fallback + Documentation

### Bug Fixes
1. Address beta feedback issues
2. Fix document parsing edge cases
3. Improve error handling for corrupted files

### Low-RAM Device Support
4. Auto-detect RAM on first launch
5. Recommend appropriate model:
   - 6GB+: Gemma 2B
   - 4-6GB: Llama 3.2 1B
6. Implement model switching

### Documentation
7. Write comprehensive README:
   - Architecture overview
   - Setup instructions
   - Model download links
8. Code comments for complex RAG logic
9. User guide within app

### Checkpoint
- [ ] Critical bugs resolved
- [ ] Low-RAM fallback working
- [ ] Documentation complete

## Week 9: Play Store + Demo + Showcase

### Play Store Preparation
1. Create app listing:
   - Screenshots (light/dark mode)
   - Feature graphic
   - Privacy policy (no data collection)
2. Prepare APK under 200MB (app shell only, models downloaded separately)
3. Submit for review

### Demo Video
4. Record 5-minute demo:
   - Offline operation (airplane mode)
   - Document ingestion
   - Query with citations
   - Privacy message
5. Edit with captions and background music

### Showcase
6. Prepare presentation:
   - Problem statement
   - Technical challenges
   - Demo
   - User testimonials from beta
7. Present at club showcase (June 30)

### Checkpoint
- [ ] App published on Play Store
- [ ] Demo video uploaded
- [ ] Repository open-sourced

## Dependencies Reference

### Flutter Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  file_picker: ^6.1.1
  syncfusion_flutter_pdf: ^24.1.41
  google_mlkit_text_recognition: ^0.11.0
  tflite_flutter: ^0.10.4
  objectbox: ^2.5.0
  objectbox_flutter_libs: ^2.5.0
  flutter_bloc: ^8.1.3
  get_it: ^7.6.4
  path_provider: ^2.1.1
  permission_handler: ^11.0.1
  shared_preferences: ^2.2.2
```

### External Models
- **Embedding**: `all-MiniLM-L6-v2` (quantized, ~25MB)
- **LLM (Default)**: Gemma 2B Q4 (~1.3GB)
- **LLM (Fallback)**: Llama 3.2 1B Q4 (~700MB)
- **Whisper**: tiny (~40MB) or base (~80MB)

## Key Implementation Notes

### Memory Management
- Unload LLM from RAM when app backgrounded (if needed)
- Batch embedding generation to avoid OOM
- Show clear loading states during heavy operations

### Privacy Guarantees
- All processing on-device
- No analytics or telemetry
- Local storage only (ObjectBox/SQLite)
- Document encryption at rest (optional)

### RAG Prompt Template
```
You are a helpful assistant answering questions based on the user's documents.
Use ONLY the provided context to answer. If the answer is not in the context, say so.

Context:
{chunk_1} [Source: {doc_name}, Page {page}]
{chunk_2} [Source: {doc_name}, Page {page}]
...

Question: {user_query}

Provide a clear, accurate answer. Cite the source document and page number for each piece of information.
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ Document     │  │ Chat         │  │ Settings         │   │
│  │ List         │  │ Interface    │  │ (Model Manager)  │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      BLoC / State                            │
│         (flutter_bloc for predictable state)               │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ Ingestion    │  │ Retrieval    │  │ Generation       │   │
│  │ Use Cases    │  │ Use Cases    │  │ Use Cases        │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ Document     │  │ Vector DB    │  │ LLM Runtime      │   │
│  │ Repository   │  │ (ObjectBox)  │  │ (llama.cpp)      │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
│  ┌──────────────┐  ┌──────────────┐                          │
│  │ File         │  │ Embedding    │                          │
│  │ Extractors   │  │ (TFLite)     │                          │
│  └──────────────┘  └──────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

## Performance Targets

| Operation | Target |
|-----------|--------|
| First PDF embedding (50 pages) | ~30 seconds |
| RAG retrieval | < 1 second |
| LLM token generation | 5-10 tokens/sec |
| End-to-end answer | 10-30 seconds |
| Cold start | 3-5 seconds |

## Risk Mitigations

| Risk | Mitigation |
|------|------------|
| APK size > 200MB | Ship empty, download models on first launch |
| Thermal throttling | Stream tokens, show thinking state |
| Low-RAM devices | Auto-fallback to smaller model |
| iOS complexity | Android-first launch |
| Trust in answers | Always show source citations |

## Testing Checklist

- [ ] PDF with tables and images
- [ ] Multi-column document layout
- [ ] OCR on handwritten notes
- [ ] Audio with background noise
- [ ] Query in different languages
- [ ] 100+ documents in library
- [ ] Airplane mode operation
- [ ] App backgrounding during inference
- [ ] Low storage scenario
- [ ] Corrupted file handling
