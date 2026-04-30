class AppConstants {
  static const String appName = 'Smriti';
  static const String appTagline = 'Your second memory, on your phone';
  
  // Storage keys
  static const String documentsKey = 'documents';
  static const String settingsKey = 'settings';
  
  // File types supported
  static const List<String> supportedExtensions = [
    // Documents
    'pdf',
    'txt',
    'docx',
    'doc',
    // Images (OCR supported)
    'png',
    'jpg',
    'jpeg',
    'webp',
    'bmp',
    'gif',
    // Audio (Transcription supported)
    'mp3',
    'wav',
    'm4a',
    'aac',
    'ogg',
    'flac',
  ];
  
  // Chunking settings
  static const int chunkSize = 500; // tokens
  static const int chunkOverlap = 50; // tokens
  
  // Model settings
  static const String defaultModelName = 'gemma-2b-q4';
  static const String fallbackModelName = 'llama-3.2-1b-q4';
  static const String embeddingModelName = 'all-minilm-l6-v2-q';
  
  // UI strings
  static const String noDocumentsMessage = 'No documents yet. Tap + to add your first document.';
  static const String offlineMessage = 'Everything runs offline. Your data never leaves your device.';
}
