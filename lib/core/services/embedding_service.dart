import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class EmbeddingService {
  static Interpreter? _interpreter;
  static const int embeddingDim = 384;
  static const int maxSequenceLength = 512;
  static const String modelName = 'all-minilm-l6-v2-q.tflite';

  static Map<String, int>? _vocab;
  static bool _vocabLoaded = false;

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
      await _loadVocab();
    } catch (e) {
      throw Exception('Failed to load embedding model: $e');
    }
  }

  static Future<void> _loadVocab() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/vocab.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      _vocab = {};
      for (var i = 0; i < list.length; i++) {
        _vocab![list[i] as String] = i;
      }
      _vocabLoaded = true;
    } catch (_) {
      _vocabLoaded = false;
    }
  }

  static Future<String> _getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelFile = File('${appDir.path}/models/$modelName');

    if (await modelFile.exists()) {
      return modelFile.path;
    }

    throw Exception('Embedding model not found. Please download the model first.');
  }

  static List<int> _wordPieceTokenize(String text) {
    final normalized = text.toLowerCase().trim();
    final words = normalized.split(RegExp(r'\s+'));
    final tokens = <int>[];

    if (_vocabLoaded) {
      tokens.add(_vocab!['[CLS]'] ?? 101);
      for (final word in words) {
        if (word.isEmpty) continue;
        if (_vocab!.containsKey(word)) {
          tokens.add(_vocab![word]!);
        } else {
          String remaining = word;
          while (remaining.isNotEmpty) {
            String bestSub = '';
            for (var i = remaining.length; i > 0; i--) {
              final sub = i < remaining.length ? '##${remaining.substring(0, i)}' : remaining.substring(0, i);
              if (_vocab!.containsKey(sub)) {
                bestSub = sub;
                break;
              }
            }
            if (bestSub.isNotEmpty) {
              tokens.add(_vocab![bestSub]!);
              remaining = remaining.substring(bestSub.replaceFirst('##', '').length);
            } else {
              tokens.add(_vocab!['[UNK]'] ?? 100);
              break;
            }
          }
        }
        if (tokens.length >= maxSequenceLength - 1) break;
      }
      tokens.add(_vocab!['[SEP]'] ?? 102);
    } else {
      tokens.addAll([
        101,
        ...words.expand((w) => w.split('').map((c) => c.codeUnitAt(0) % 30000 + 1)),
        102,
      ]);
    }

    if (tokens.length > maxSequenceLength) {
      return tokens.sublist(0, maxSequenceLength - 1)..add(102);
    }
    return tokens;
  }

  static Future<List<double>> embed(String text) async {
    if (_interpreter == null) {
      throw StateError('EmbeddingService not initialized');
    }

    final tokenIds = _wordPieceTokenize(text);

    final inputShape = [1, maxSequenceLength];
    final inputBuffer = Int32List(maxSequenceLength);
    final attentionMask = Int32List(maxSequenceLength);
    final tokenTypeIds = Int32List(maxSequenceLength);

    for (var i = 0; i < min(tokenIds.length, maxSequenceLength); i++) {
      inputBuffer[i] = tokenIds[i];
      attentionMask[i] = 1;
    }

    final input = [inputBuffer.reshape(inputShape), attentionMask.reshape(inputShape), tokenTypeIds.reshape(inputShape)];
    final outputMap = <int, Object>{0: List.filled(embeddingDim, 0.0).reshape([1, embeddingDim])};

    _interpreter!.runForMultipleInputs(input, outputMap);

    final embedding = (outputMap[0] as List)[0] as List<double>;
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
    _vocab = null;
    _vocabLoaded = false;
  }
}
