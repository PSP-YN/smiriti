class AppConstants {
  AppConstants._();

  // ── App identity ──────────────────────────────────────────────────────────
  static const String appName = 'Smriti';
  static const String appTagline = 'Your second memory, on your phone';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  static const String privacyPolicyDate = 'May 2025';

  // ── Supported file types ──────────────────────────────────────────────────
  static const List<String> supportedExtensions = [
    // Documents
    'pdf', 'txt',
    // Images (OCR)
    'png', 'jpg', 'jpeg', 'webp', 'bmp',
    // Audio (transcription)
    'mp3', 'wav', 'm4a', 'aac', 'ogg',
  ];

  static const List<String> documentExtensions = ['pdf', 'txt'];
  static const List<String> imageExtensions = ['png', 'jpg', 'jpeg', 'webp', 'bmp'];
  static const List<String> audioExtensions = ['mp3', 'wav', 'm4a', 'aac', 'ogg'];

  // ── Chunking ──────────────────────────────────────────────────────────────
  static const int chunkSize = 500; // characters (~125 tokens)
  static const int chunkOverlap = 50; // character overlap between chunks

  // ── Model identifiers ─────────────────────────────────────────────────────
  static const String defaultModelId = 'gemma-2b-q4';
  static const String fallbackModelId = 'llama-3.2-1b-q4';
  static const String embeddingModelId = 'all-minilm-l6-v2';

  // ── UI strings ────────────────────────────────────────────────────────────
  static const String noDocumentsMessage =
      'No documents yet.\nTap + to add your first document.';
  static const String offlineMessage =
      'Everything runs offline. Your data never leaves your device.';

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String documentsKey = 'smriti_documents_v2';
}
