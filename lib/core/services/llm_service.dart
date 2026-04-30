import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'model_manager.dart';

// FFI bindings for llama.cpp
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

class LLMService {
  static DynamicLibrary? _library;
  static Pointer<Void>? _context;
  static bool _isInitialized = false;
  static bool _isGenerating = false;
  static final _tokenStreamController = StreamController<String>.broadcast();
  
  static Stream<String> get tokenStream => _tokenStreamController.stream;
  static bool get isInitialized => _isInitialized;
  static bool get isGenerating => _isGenerating;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load the llama.cpp library
      _library = _loadLibrary();
      
      // Check if model is available
      final modelPath = await ModelManager.getDefaultModelPath();
      if (modelPath == null) {
        throw StateError('No LLM model available. Please download a model first.');
      }

      // Initialize llama context
      await _initContext(modelPath);
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('LLM initialization error: $e');
      rethrow;
    }
  }

  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libllama.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libllama.so');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libllama.dylib');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('llama.dll');
    }
    throw UnsupportedError('Platform not supported');
  }

  static Future<void> _initContext(String modelPath) async {
    // In production, this calls llama.cpp via FFI
    // For now, we simulate the initialization
    
    // TODO: Implement actual FFI bindings
    // final init = _library!.lookupFunction<LlamaInitNative, LlamaInit>('llama_init');
    // _context = init(modelPath.toNativeUtf8());
    
    // Simulate loading delay
    await Future.delayed(const Duration(seconds: 2));
    
    debugPrint('LLM context initialized with model: $modelPath');
  }

  static Future<String> generate(
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
    void Function(String token)? onToken,
  }) async {
    if (!_isInitialized) {
      throw StateError('LLM not initialized');
    }

    if (_isGenerating) {
      throw StateError('Already generating. Wait for completion.');
    }

    _isGenerating = true;
    
    try {
      // TODO: Implement actual FFI call
      // final predict = _library!.lookupFunction<LlamaPredictNative, LlamaPredict>('llama_predict');
      // final result = predict(_context!, prompt.toNativeUtf8(), maxTokens, temperature, topP);
      // return result.toDartString();

      // Simulate streaming generation
      final response = await _simulateGeneration(prompt, maxTokens, onToken);
      return response;
    } finally {
      _isGenerating = false;
    }
  }

  static Future<String> generateWithRAG(
    String query,
    List<Map<String, dynamic>> contextChunks, {
    int maxTokens = 512,
    double temperature = 0.7,
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

  static String _buildRAGPrompt(String query, List<Map<String, dynamic>> chunks) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are a helpful assistant answering questions based on the user\'s documents.');
    buffer.writeln('Use ONLY the provided context to answer. If the answer is not in the context, say so.');
    buffer.writeln();
    buffer.writeln('Context:');
    
    for (var i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final docName = chunk['docName'] ?? 'Unknown';
      final page = chunk['page'] ?? 0;
      final content = chunk['content'] ?? '';
      
      buffer.writeln('[${i + 1}] From "$docName" (Page $page):');
      buffer.writeln(content);
      buffer.writeln();
    }
    
    buffer.writeln('Question: $query');
    buffer.writeln();
    buffer.writeln('Provide a clear, accurate answer. Cite the source number [1], [2], etc. when referring to information.');
    buffer.writeln('Answer:');
    
    return buffer.toString();
  }

  static Future<String> _simulateGeneration(
    String prompt,
    int maxTokens,
    void Function(String token)? onToken,
  ) async {
    // Simulate token-by-token generation
    // In production, this streams from llama.cpp
    
    final simulatedResponse = _getSimulatedResponse(prompt);
    final tokens = simulatedResponse.split(' ');
    final buffer = StringBuffer();
    
    for (final token in tokens) {
      await Future.delayed(const Duration(milliseconds: 50)); // Simulate 20 tokens/sec
      buffer.write('$token ');
      
      if (onToken != null) {
        onToken('$token ');
      }
      
      _tokenStreamController.add('$token ');
    }
    
    return buffer.toString().trim();
  }

  static String _getSimulatedResponse(String prompt) {
    // This is a placeholder - in production, llama.cpp returns actual inference results
    if (prompt.contains('Question:')) {
      return 'Based on the documents you provided, I found relevant information that answers your question. '
          '[1] The context shows detailed information about this topic. '
          'Please note that this is a simulated response for Week 3 testing. '
          'In the full implementation, the Gemma 2B model will generate actual answers based on your documents.';
    }
    
    return 'This is a placeholder response from the LLM simulation. '
        'The actual llama.cpp integration will provide real inference results.';
  }

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

  static Future<Map<String, dynamic>> getModelInfo() async {
    final modelPath = await ModelManager.getDefaultModelPath();
    if (modelPath == null) {
      return {'available': false};
    }

    final file = File(modelPath);
    if (!await file.exists()) {
      return {'available': false};
    }

    final size = await file.length();
    final modelName = modelPath.split('/').last;
    
    return {
      'available': true,
      'name': modelName,
      'path': modelPath,
      'size': size,
      'sizeMB': (size / 1024 / 1024).toStringAsFixed(2),
    };
  }
}
