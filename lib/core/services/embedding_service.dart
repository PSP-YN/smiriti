import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class EmbeddingService {
  static Interpreter? _interpreter;
  static const int embeddingDim = 384;
  static const int maxSequenceLength = 512;
  static const String modelName = 'all-minilm-l6-v2-q.tflite';
  
  static bool get isInitialized => _interpreter != null;

  static Future<void> initialize() async {
    if (_interpreter != null) return;

    try {
      final modelPath = await _getModelPath();
      _interpreter = Interpreter.fromFile(
        File(modelPath),
        options: InterpreterOptions()
          ..threads = 4
          ..useNnApiForAndroid = true,
      );
    } catch (e) {
      throw Exception('Failed to load embedding model: $e');
    }
  }

  static Future<String> _getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelFile = File('${appDir.path}/models/$modelName');

    if (await modelFile.exists()) {
      return modelFile.path;
    }

    // Model not downloaded yet - return placeholder path
    // In production, this would trigger a download
    throw Exception('Embedding model not found. Please download the model first.');
  }

  static Future<List<double>> embed(String text) async {
    if (_interpreter == null) {
      throw StateError('EmbeddingService not initialized');
    }

    // Simple tokenization (word-based for now)
    // In production, use proper tokenizer from transformers
    final tokens = _simpleTokenize(text);
    final inputShape = [1, maxSequenceLength];
    final inputBuffer = Float32List(maxSequenceLength);
    
    // Fill input with token IDs (simplified)
    for (var i = 0; i < min(tokens.length, maxSequenceLength); i++) {
      inputBuffer[i] = tokens[i];
    }

    // Create input tensor
    final input = inputBuffer.reshape(inputShape);
    final output = List.filled(embeddingDim, 0.0).reshape([1, embeddingDim]);

    _interpreter!.run(input, output);

    // Normalize the embedding
    final embedding = (output[0] as List<double>);
    return _normalize(embedding);
  }

  static Future<List<List<double>>> embedBatch(List<String> texts) async {
    if (_interpreter == null) {
      throw StateError('EmbeddingService not initialized');
    }

    final results = <List<double>>[];
    for (final text in texts) {
      results.add(await embed(text));
    }
    return results;
  }

  static List<double> _simpleTokenize(String text) {
    // Simplified tokenization - in production, use WordPiece/BPE tokenizer
    // This is a placeholder that creates pseudo-token IDs from character codes
    final normalized = text.toLowerCase().trim();
    final tokens = <double>[];
    
    for (var i = 0; i < normalized.length && i < maxSequenceLength; i++) {
      tokens.add((normalized.codeUnitAt(i) % 30000).toDouble() + 1);
    }
    
    return tokens;
  }

  static List<double> _normalize(List<double> vector) {
    var sum = 0.0;
    for (final val in vector) {
      sum += val * val;
    }
    final magnitude = sqrt(sum);
    
    if (magnitude == 0) return vector;
    
    return vector.map((v) => v / magnitude).toList();
  }

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have same length');
    }

    var dotProduct = 0.0;
    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
    }

    return dotProduct;
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
