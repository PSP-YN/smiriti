import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import 'model_manager.dart';
import 'remote_llm_service.dart';
import 'secure_storage_service.dart';

// ── FFI typedefs (llama.cpp) ──────────────────────────────────────────────────

typedef LlamaInitNative = Pointer<Void> Function(Pointer<Utf8> modelPath);
typedef LlamaInit = Pointer<Void> Function(Pointer<Utf8> modelPath);

typedef LlamaPredictNative = Pointer<Utf8> Function(
  Pointer<Void> ctx,
  Pointer<Utf8> prompt,
  Int32 maxTokens,
  Float temperature,
  Float topP,
);
typedef LlamaPredict = Pointer<Utf8> Function(
  Pointer<Void> ctx,
  Pointer<Utf8> prompt,
  int maxTokens,
  double temperature,
  double topP,
);

typedef LlamaFreeNative = Void Function(Pointer<Void> ctx);
typedef LlamaFree = void Function(Pointer<Void> ctx);

// ── LLM Service ───────────────────────────────────────────────────────────────

class LLMService {
  LLMService._();

  static DynamicLibrary? _library;
  static Pointer<Void>? _context;
  static bool _isInitialized = false;
  static bool _isGenerating = false;

  static final _tokenStreamController = StreamController<String>.broadcast();
  static Stream<String> get tokenStream => _tokenStreamController.stream;
  static bool get isInitialized => _isInitialized;
  static bool get isGenerating => _isGenerating;

  // ── Initialization ────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_isInitialized) return;

    final modelPath = await ModelManager.getDefaultModelPath();
    if (modelPath == null) {
      throw StateError(
          'No LLM model found. Please download a model from Settings → AI Models.');
    }

    try {
      _library = _loadLibrary();
      await _initContext(modelPath);
      _isInitialized = true;
    } catch (e) {
      debugPrint('LLM initialization error: $e');
      rethrow;
    }
  }

  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) return DynamicLibrary.open('libllama.so');
    if (Platform.isIOS) return DynamicLibrary.process();
    if (Platform.isLinux) return DynamicLibrary.open('libllama.so');
    if (Platform.isMacOS) return DynamicLibrary.open('libllama.dylib');
    if (Platform.isWindows) return DynamicLibrary.open('llama.dll');
    throw UnsupportedError('Platform not supported: ${Platform.operatingSystem}');
  }

  static Future<void> _initContext(String modelPath) async {
    // TODO: Implement actual FFI binding to llama.cpp
    // final init = _library!.lookupFunction<LlamaInitNative, LlamaInit>('llama_init');
    // _context = init(modelPath.toNativeUtf8());
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('LLM context initialized: $modelPath');
  }

  // ── Text generation ───────────────────────────────────────────────────────

  static Future<String> generate(
    String prompt, {
    int maxTokens = AppConstants.llmMaxTokens,
    double temperature = AppConstants.llmTemperature,
    double topP = AppConstants.llmTopP,
    void Function(String token)? onToken,
  }) async {
    final providerStr = await SecureStorageService.getActiveProvider();
    final provider = LLMProvider.values.firstWhere(
      (e) => e.name == providerStr,
      orElse: () => LLMProvider.local,
    );

    if (provider != LLMProvider.local) {
      return RemoteLLMService.generate(
        prompt: prompt,
        provider: provider,
        maxTokens: maxTokens,
        temperature: temperature,
      );
    }

    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        throw StateError('Local LLM not initialized and failed to auto-initialize: $e');
      }
    }

    if (_isGenerating) throw StateError('Already generating. Please wait.');

    _isGenerating = true;
    try {
      // TODO: Replace with actual FFI call:
      // final predict = _library!.lookupFunction<LlamaPredictNative, LlamaPredict>('llama_predict');
      // final resultPtr = predict(_context!, prompt.toNativeUtf8(), maxTokens, temperature, topP);
      // return resultPtr.toDartString();
      return await _simulateGeneration(prompt, maxTokens, onToken);
    } finally {
      _isGenerating = false;
    }
  }

  // ── RAG generation ────────────────────────────────────────────────────────

  static Future<String> generateWithRAG(
    String query,
    List<Map<String, dynamic>> contextChunks, {
    int maxTokens = AppConstants.llmMaxTokens,
    double temperature = AppConstants.llmTemperature,
    void Function(String token)? onToken,
  }) async {
    final prompt = _buildRAGPrompt(query, contextChunks);
    return generate(
      prompt,
      maxTokens: maxTokens,
      temperature: temperature,
      onToken: onToken,
    );
  }

  static String _buildRAGPrompt(
      String query, List<Map<String, dynamic>> chunks) {
    final buf = StringBuffer();

    buf.writeln(
        '<|system|>You are Smriti, an elite, precise document assistant. '
        'Answer EXCLUSIVELY from the provided context. '
        'Be comprehensive and detailed — minimum 98% accuracy. '
        'Cite sources as [1], [2], … in your answer. '
        'If the answer is NOT in the context, reply: '
        '"I could not find this information in your documents." '
        'Never hallucinate or fabricate facts.</|system|>');
    buf.writeln();

    buf.writeln('<|context|>');
    for (var i = 0; i < chunks.length; i++) {
      final docName = chunks[i]['docName'] ?? 'Unknown';
      final page = chunks[i]['page'] ?? 0;
      final content = chunks[i]['content'] ?? '';
      buf.writeln('[${i + 1}] From "$docName", Page $page:');
      buf.writeln(content);
      buf.writeln();
    }
    buf.writeln('</|context|>');
    buf.writeln();
    buf.writeln('<|user|>$query</|user|>');
    buf.writeln('<|assistant|>');

    return buf.toString();
  }

  // ── Simulation (placeholder until FFI is wired up) ────────────────────────

  static Future<String> _simulateGeneration(
    String prompt,
    int maxTokens,
    void Function(String token)? onToken,
  ) async {
    final response = _buildSimulatedResponse(prompt);
    final words = response.split(' ');
    final buf = StringBuffer();

    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 40)); // ~25 tok/s
      buf.write('$word ');
      onToken?.call('$word ');
      _tokenStreamController.add('$word ');
    }

    return buf.toString().trim();
  }

  static String _buildSimulatedResponse(String prompt) {
    if (prompt.contains('<|context|>')) {
      return 'Based on the documents you provided, here is a detailed answer to your question. '
          '[1] The relevant sections clearly indicate the information you requested. '
          'Please download an LLM model from Settings → AI Models to receive '
          'fully AI-generated responses powered by the Gemma 2B or Llama 3.2 model.';
    }
    return 'This is a placeholder. Download a model in Settings → AI Models '
        'for real AI-powered answers.';
  }

  // ── Disposal ──────────────────────────────────────────────────────────────

  static void dispose() {
    if (_context != null && _library != null) {
      try {
        // final free = _library!.lookupFunction<LlamaFreeNative, LlamaFree>('llama_free');
        // free(_context!);
      } catch (e) {
        debugPrint('Error freeing LLM context: $e');
      }
      _context = null;
    }
    _isInitialized = false;
    _isGenerating = false;
  }

  // ── Model info ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getModelInfo() async {
    final modelPath = await ModelManager.getDefaultModelPath();
    if (modelPath == null) return {'available': false};

    final file = File(modelPath);
    if (!await file.exists()) return {'available': false};

    final size = await file.length();
    return {
      'available': true,
      'name': modelPath.split('/').last,
      'path': modelPath,
      'size': size,
      'sizeMB': (size / 1024 / 1024).toStringAsFixed(2),
    };
  }
}
