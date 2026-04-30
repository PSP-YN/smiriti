import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Transcription result
class TranscriptionResult {
  final String text;
  final String? language;
  final List<TranscriptionSegment> segments;
  final double duration;
  final double confidence;
  final DateTime processedAt;

  const TranscriptionResult({
    required this.text,
    this.language,
    required this.segments,
    required this.duration,
    this.confidence = 0.0,
    required this.processedAt,
  });

  /// Get formatted timestamp text
  String get timestampedText {
    final buffer = StringBuffer();
    for (final segment in segments) {
      buffer.writeln('[${_formatDuration(segment.start)}] ${segment.text}');
    }
    return buffer.toString();
  }

  String _formatDuration(double seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

/// Individual transcription segment with timing
class TranscriptionSegment {
  final int id;
  final double start;
  final double end;
  final String text;
  final double confidence;
  final List<WordTimestamp> words;

  const TranscriptionSegment({
    required this.id,
    required this.start,
    required this.end,
    required this.text,
    this.confidence = 0.0,
    this.words = const [],
  });

  /// Duration of segment in seconds
  double get duration => end - start;
}

/// Word-level timestamp
class WordTimestamp {
  final String word;
  final double start;
  final double end;
  final double confidence;

  const WordTimestamp({
    required this.word,
    required this.start,
    required this.end,
    this.confidence = 0.0,
  });
}

/// Audio processing configuration
class TranscriptionConfig {
  final String language; // 'auto', 'en', 'hi', 'ta', etc.
  final bool translateToEnglish;
  final bool wordTimestamps;
  final int beamSize;
  final double patience;
  final double temperature;

  const TranscriptionConfig({
    this.language = 'auto',
    this.translateToEnglish = false,
    this.wordTimestamps = false,
    this.beamSize = 5,
    this.patience = 1.0,
    this.temperature = 0.0,
  });
}

/// Audio transcription service using whisper.cpp
class AudioTranscriptionService {
  static DynamicLibrary? _library;
  static bool _isInitialized = false;
  static bool _isProcessing = false;
  static String? _modelPath;
  
  static final _progressController = StreamController<double>.broadcast();
  static Stream<double> get progressStream => _progressController.stream;

  static bool get isInitialized => _isInitialized;
  static bool get isProcessing => _isProcessing;

  /// Initialize the transcription service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load native library
      _library = _loadLibrary();
      
      // Check for whisper model
      final modelPath = await _getModelPath();
      _modelPath = modelPath;
      if (_modelPath == null) {
        debugPrint('No whisper model available. Transcription will use simulation.');
      } else {
        // Initialize whisper context
        await _initWhisper(_modelPath!);
      }
      
      _isInitialized = true;
      debugPrint('Audio transcription service initialized');
    } catch (e) {
      debugPrint('Audio transcription initialization error: $e');
      // Don't throw - service can work in simulation mode
      _isInitialized = true;
    }
  }

  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libwhisper.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libwhisper.so');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libwhisper.dylib');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('whisper.dll');
    }
    throw UnsupportedError('Platform not supported');
  }

  static Future<String?> _getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    
    if (!await modelsDir.exists()) return null;

    // Look for whisper model files
    final whisperModels = [
      'whisper-tiny-q5_1.bin',
      'whisper-base-q5_1.bin',
      'whisper-small-q5_1.bin',
    ];

    for (final modelName in whisperModels) {
      final modelFile = File('${modelsDir.path}/$modelName');
      if (await modelFile.exists()) {
        return modelFile.path;
      }
    }

    return null;
  }

  static Future<void> _initWhisper(String modelPath) async {
    // In production, initialize whisper.cpp context
    // For Week 5, we simulate initialization
    debugPrint('Initializing whisper with model: $modelPath');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Transcribe audio file
  static Future<TranscriptionResult> transcribe(
    String audioPath, {
    TranscriptionConfig config = const TranscriptionConfig(),
    void Function(double progress)? onProgress,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isProcessing) {
      throw StateError('Already processing an audio file');
    }

    _isProcessing = true;
    _progressController.add(0.0);

    try {
      // Get audio duration
      final duration = await _getAudioDuration(audioPath);

      // Convert audio to required format (16kHz, mono, WAV)
      final wavPath = await _convertToWav(audioPath);

      // Perform transcription
      TranscriptionResult result;
      if (_modelPath != null) {
        result = await _transcribeWithWhisper(wavPath, duration, config, onProgress);
      } else {
        result = await _simulateTranscription(wavPath, duration, config, onProgress);
      }

      // Clean up temp WAV file
      if (wavPath != audioPath) {
        final wavFile = File(wavPath);
        if (await wavFile.exists()) {
          await wavFile.delete();
        }
      }

      return result;
    } finally {
      _isProcessing = false;
      _progressController.add(1.0);
    }
  }

  /// Get audio file duration in seconds
  static Future<double> _getAudioDuration(String audioPath) async {
    // In production, use audio metadata
    // For simulation, return a reasonable estimate
    return 60.0; // Default 1 minute
  }

  /// Convert audio to WAV format (16kHz, mono, 16-bit)
  static Future<String> _convertToWav(String audioPath) async {
    final ext = audioPath.toLowerCase().split('.').last;
    
    // If already WAV, check format
    if (ext == 'wav') {
      // Verify it's 16kHz mono
      // For now, assume it is
      return audioPath;
    }

    // Convert using FFmpeg (in production)
    // For Week 5, simulate conversion
    debugPrint('Converting $ext to WAV format...');
    await Future.delayed(const Duration(seconds: 1));

    // Return original path (simulation)
    return audioPath;
  }

  /// Transcribe using whisper.cpp
  static Future<TranscriptionResult> _transcribeWithWhisper(
    String wavPath,
    double duration,
    TranscriptionConfig config,
    void Function(double progress)? onProgress,
  ) async {
    // In production, this calls whisper.cpp via FFI
    // For Week 5, we simulate the transcription

    final segments = <TranscriptionSegment>[];
    final segmentDuration = 30.0; // 30 seconds per segment
    final numSegments = (duration / segmentDuration).ceil();

    for (int i = 0; i < numSegments; i++) {
      final progress = (i + 1) / numSegments;
      _progressController.add(progress * 0.8); // 80% for transcription
      onProgress?.call(progress * 0.8);

      await Future.delayed(const Duration(milliseconds: 500));

      final start = i * segmentDuration;
      final end = (start + segmentDuration).clamp(0, duration);

      segments.add(TranscriptionSegment(
        id: i,
        start: start,
        end: end.toDouble(),
        text: _getSimulatedTranscript(i),
        confidence: 0.85 + (progress * 0.1), // Increasing confidence
      ));
    }

    // Combine all text
    final fullText = segments.map((s) => s.text).join(' ');

    return TranscriptionResult(
      text: fullText,
      language: config.language == 'auto' ? 'en' : config.language,
      segments: segments,
      duration: duration,
      confidence: 0.9,
      processedAt: DateTime.now(),
    );
  }

  /// Simulate transcription for testing
  static Future<TranscriptionResult> _simulateTranscription(
    String audioPath,
    double duration,
    TranscriptionConfig config,
    void Function(double progress)? onProgress,
  ) async {
    final segments = <TranscriptionSegment>[];
    final segmentCount = (duration / 10).ceil(); // 10 sec segments

    for (int i = 0; i < segmentCount; i++) {
      final progress = (i + 1) / segmentCount;
      _progressController.add(progress * 0.5);
      onProgress?.call(progress * 0.5);
      await Future.delayed(const Duration(milliseconds: 200));

      segments.add(TranscriptionSegment(
        id: i,
        start: i * 10.0,
        end: ((i + 1) * 10.0).clamp(0, duration),
        text: '[Segment ${i + 1}] Transcribed text from audio file.',
        confidence: 0.8,
      ));
    }

    return TranscriptionResult(
      text: 'Simulated transcription: This is placeholder text for audio transcription. '
          'In production, whisper.cpp will provide accurate speech-to-text conversion '
          'supporting multiple languages including English, Hindi, Tamil, and more.',
      language: config.language == 'auto' ? 'en' : config.language,
      segments: segments,
      duration: duration,
      confidence: 0.85,
      processedAt: DateTime.now(),
    );
  }

  static String _getSimulatedTranscript(int segmentIndex) {
    final samples = [
      'Welcome to this presentation on machine learning fundamentals.',
      'Today we will cover neural networks and deep learning concepts.',
      'The key idea is to build systems that learn from data.',
      'This approach has revolutionized computer vision and NLP.',
      'Let us begin with the basics of neural network architecture.',
      'A neuron takes inputs, applies weights, and produces output.',
      'Multiple neurons form layers, and layers form networks.',
      'Training involves adjusting weights to minimize error.',
    ];
    return samples[segmentIndex % samples.length];
  }

  /// Batch transcribe multiple audio files
  static Future<List<TranscriptionResult>> batchTranscribe(
    List<String> audioPaths, {
    TranscriptionConfig config = const TranscriptionConfig(),
  }) async {
    final results = <TranscriptionResult>[];

    for (final path in audioPaths) {
      try {
        final result = await transcribe(path, config: config);
        results.add(result);
      } catch (e) {
        debugPrint('Failed to transcribe $path: $e');
      }
    }

    return results;
  }

  /// Transcribe with real-time streaming (for live audio)
  static Stream<String> streamTranscribe(
    Stream<Uint8List> audioStream, {
    TranscriptionConfig config = const TranscriptionConfig(),
  }) async* {
    // In production, process audio chunks in real-time
    // For Week 5, yield placeholder tokens
    
    await for (final chunk in audioStream) {
      // Process chunk
      await Future.delayed(const Duration(milliseconds: 100));
      yield '[Processing ${chunk.length} bytes...]';
    }
  }

  /// Get available whisper models
  static Future<List<Map<String, dynamic>>> getAvailableModels() async {
    return [
      {
        'id': 'whisper-tiny',
        'name': 'Whisper Tiny',
        'sizeMB': 75,
        'languages': 'Multilingual',
        'speed': 'Fastest',
        'accuracy': 'Good',
      },
      {
        'id': 'whisper-base',
        'name': 'Whisper Base',
        'sizeMB': 150,
        'languages': 'Multilingual',
        'speed': 'Fast',
        'accuracy': 'Better',
      },
      {
        'id': 'whisper-small',
        'name': 'Whisper Small',
        'sizeMB': 500,
        'languages': 'Multilingual',
        'speed': 'Medium',
        'accuracy': 'Best',
      },
    ];
  }

  /// Check if transcription is available
  static Future<bool> isAvailable() async {
    return true; // Always available (with simulation fallback)
  }

  /// Dispose resources
  static void dispose() {
    _library = null;
    _isInitialized = false;
    _isProcessing = false;
    _modelPath = null;
    _progressController.close();
  }
}
