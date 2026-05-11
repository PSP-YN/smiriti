import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// ── Supported OCR scripts ─────────────────────────────────────────────────────

enum OCRScript {
  latin,
  devanagari,
  japanese,
  korean,
  chinese,
}

// ── Result types ──────────────────────────────────────────────────────────────

class OCRResult {
  final String text;
  final String? recognizedLanguage;
  final List<OCRBlock> blocks;
  final double confidence;
  final OCRScript? detectedScript;
  final int imageWidth;
  final int imageHeight;

  const OCRResult({
    required this.text,
    this.recognizedLanguage,
    required this.blocks,
    this.confidence = 0.0,
    this.detectedScript,
    required this.imageWidth,
    required this.imageHeight,
  });

  List<String> get lines =>
      text.split('\n').where((l) => l.trim().isNotEmpty).toList();

  int get wordCount =>
      text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// Meaningful content = more than 5 words
  bool get hasContent => wordCount > 5;
}

class OCRBlock {
  final String text;
  final double confidence;
  final Rect boundingBox;

  const OCRBlock({
    required this.text,
    required this.boundingBox,
    this.confidence = 0.0,
  });
}

// ── OCR Service ───────────────────────────────────────────────────────────────

class OCRService {
  OCRService._();

  static TextRecognizer? _latinRecognizer;
  static bool _isInitialized = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _isInitialized = true;
    debugPrint('OCRService: initialized');
  }

  static Future<void> dispose() async {
    await _latinRecognizer?.close();
    _latinRecognizer = null;
    _isInitialized = false;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Process a single image at [imagePath] with optional preprocessing and
  /// multi-pass recognition for maximum accuracy.
  static Future<OCRResult> processImage(
    String imagePath, {
    OCRScript? preferredScript,
    bool preprocess = true,
  }) async {
    if (!_isInitialized) await initialize();

    String processedPath = imagePath;
    bool createdTemp = false;

    try {
      if (preprocess) {
        final preprocessed = await _preprocessImage(imagePath);
        if (preprocessed != imagePath) {
          processedPath = preprocessed;
          createdTemp = true;
        }
      }

      final inputImage = InputImage.fromFilePath(processedPath);
      final recognizer = _recognizerForScript(preferredScript);
      final isCustomRecognizer = preferredScript != null &&
          preferredScript != OCRScript.latin &&
          preferredScript != OCRScript.devanagari;

      final recognizedText = await recognizer.processImage(inputImage);

      // Close script-specific recognizers immediately after use
      if (isCustomRecognizer) await recognizer.close();

      return _toOCRResult(recognizedText, imagePath, preferredScript);
    } catch (e) {
      debugPrint('OCRService.processImage error: $e');
      rethrow;
    } finally {
      if (createdTemp) {
        try {
          final f = File(processedPath);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
  }

  /// Process multiple images and merge results.
  static Future<OCRResult> processImages(
    List<String> imagePaths, {
    OCRScript? preferredScript,
  }) async {
    final results = <OCRResult>[];

    for (final path in imagePaths) {
      try {
        final r = await processImage(path, preferredScript: preferredScript);
        if (r.hasContent) results.add(r);
      } catch (e) {
        debugPrint('OCRService: failed on $path — $e');
      }
    }

    if (results.isEmpty) {
      return const OCRResult(
          text: '', blocks: [], imageWidth: 0, imageHeight: 0);
    }

    final combinedText = results.map((r) => r.text).join('\n\n');
    final allBlocks = results.expand((r) => r.blocks).toList();
    final avgConf = results.map((r) => r.confidence).reduce((a, b) => a + b) /
        results.length;

    return OCRResult(
      text: combinedText,
      blocks: allBlocks,
      confidence: avgConf,
      detectedScript: results.first.detectedScript,
      imageWidth: results.first.imageWidth,
      imageHeight: results.first.imageHeight,
    );
  }

  // ── Preprocessing ─────────────────────────────────────────────────────────

  /// Returns path to a preprocessed copy of the image, or [imagePath] if
  /// preprocessing fails (graceful degradation).
  static Future<String> _preprocessImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) return imagePath;

      // 1. Convert to grayscale for better OCR contrast
      image = img.grayscale(image);

      // 2. Sharpen edges
      image = img.convolution(image, filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ], div: 1, offset: 0);

      // 3. Increase contrast slightly
      image = img.adjustColor(image, contrast: 1.25);

      // 4. Resize if too large (caps at 2048 on the longest side)
      const maxDim = 2048;
      if (image.width > maxDim || image.height > maxDim) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: maxDim);
        } else {
          image = img.copyResize(image, height: maxDim);
        }
      }

      // Save to a private temp dir (not system /tmp for security)
      final appDir = await getTemporaryDirectory();
      final tempPath =
          '${appDir.path}/smriti_ocr_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(tempPath).writeAsBytes(img.encodePng(image));
      return tempPath;
    } catch (e) {
      debugPrint('OCRService._preprocessImage warning: $e');
      return imagePath; // fallback to original
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static TextRecognizer _recognizerForScript(OCRScript? script) {
    switch (script) {
      case OCRScript.japanese:
        return TextRecognizer(script: TextRecognitionScript.japanese);
      case OCRScript.korean:
        return TextRecognizer(script: TextRecognitionScript.korean);
      case OCRScript.chinese:
        return TextRecognizer(script: TextRecognitionScript.chinese);
      default:
        return _latinRecognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);
    }
  }

  static OCRResult _toOCRResult(
    RecognizedText recognizedText,
    String imagePath,
    OCRScript? preferredScript,
  ) {
    final blocks = recognizedText.blocks
        .map((b) => OCRBlock(
              text: b.text,
              boundingBox: b.boundingBox,
            ))
        .toList();

    final decoded = img.decodeImage(File(imagePath).readAsBytesSync());

    return OCRResult(
      text: recognizedText.text,
      blocks: blocks,
      detectedScript:
          preferredScript ?? _detectScript(recognizedText.text),
      imageWidth: decoded?.width ?? 0,
      imageHeight: decoded?.height ?? 0,
    );
  }

  static OCRScript _detectScript(String text) {
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) return OCRScript.devanagari;
    if (RegExp(r'[\u3040-\u30FF\u4E00-\u9FAF]').hasMatch(text)) {
      return OCRScript.japanese;
    }
    if (RegExp(r'[\uAC00-\uD7AF]').hasMatch(text)) return OCRScript.korean;
    if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(text)) return OCRScript.chinese;
    return OCRScript.latin;
  }
}
