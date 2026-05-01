import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Supported OCR scripts/languages
enum OCRScript {
  latin,      // English, European languages
  devanagari, // Hindi, Sanskrit, Marathi
  japanese,   // Japanese
  korean,     // Korean
  chinese,    // Chinese (Simplified & Traditional)
}

/// OCR processing result
class OCRResult {
  final String text;
  final String? recognizedLanguage;
  final List<TextBlock> blocks;
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

  /// Get text organized by lines
  List<String> get lines {
    return text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  /// Get word count
  int get wordCount {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Check if result has meaningful content
  bool get hasContent => text.trim().length > 10;
}

/// Text block with position info
class TextBlock {
  final String text;
  final List<TextLine> lines;
  final BoundingBox boundingBox;
  final double confidence;

  const TextBlock({
    required this.text,
    required this.lines,
    required this.boundingBox,
    this.confidence = 0.0,
  });
}

/// Text line with words
class TextLine {
  final String text;
  final List<TextWord> words;
  final BoundingBox boundingBox;
  final double confidence;

  const TextLine({
    required this.text,
    required this.words,
    required this.boundingBox,
    this.confidence = 0.0,
  });
}

/// Individual word
class TextWord {
  final String text;
  final BoundingBox boundingBox;
  final double confidence;

  const TextWord({
    required this.text,
    required this.boundingBox,
    this.confidence = 0.0,
  });
}

/// Bounding box for text elements
class BoundingBox {
  final int left;
  final int top;
  final int right;
  final int bottom;
  final int width;
  final int height;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.width,
    required this.height,
  });

  double get area => (width * height).toDouble();
}

/// OCR Service using Google ML Kit
class OCRService {
  static TextRecognizer? _textRecognizer;
  static bool _isInitialized = false;

  /// Initialize the OCR service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Use the default text recognizer (Latin script)
    // For other scripts, we'd create specific recognizers
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    _isInitialized = true;
    debugPrint('OCR Service initialized');
  }

  /// Get appropriate recognizer for script
  static TextRecognizer _getRecognizerForScript(OCRScript? script) {
    // google_mlkit_text_recognition uses script parameter
    // Available scripts: latin, chinese, japanese, korean, devanagari (if supported)
    switch (script) {
      case OCRScript.japanese:
        return TextRecognizer(script: TextRecognitionScript.japanese);
      case OCRScript.korean:
        return TextRecognizer(script: TextRecognitionScript.korean);
      case OCRScript.chinese:
        return TextRecognizer(script: TextRecognitionScript.chinese);
      case OCRScript.devanagari:
      case OCRScript.latin:
      default:
        // Devanagari and Latin use default/latin script
        return TextRecognizer(script: TextRecognitionScript.latin);
    }
  }

  /// Process image file and extract text
  static Future<OCRResult> processImage(
    String imagePath, {
    OCRScript? preferredScript,
    bool preprocess = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Preprocess image if needed
      String processedPath = imagePath;
      if (preprocess) {
        processedPath = await _preprocessImage(imagePath);
      }

      // Create input image
      final inputImage = InputImage.fromFilePath(processedPath);

      // Get appropriate recognizer
      final recognizer = preferredScript != null 
          ? _getRecognizerForScript(preferredScript)
          : _textRecognizer!;

      // Process image
      final recognizedText = await recognizer.processImage(inputImage);

      // Convert to our model
      final result = _convertToOCRResult(
        recognizedText, 
        imagePath,
        preferredScript,
      );

      // Clean up temp file if preprocessing created one
      if (preprocess && processedPath != imagePath) {
        final tempFile = File(processedPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      // Dispose script-specific recognizer
      if (preferredScript != null && recognizer != _textRecognizer) {
        await recognizer.close();
      }

      return result;
    } catch (e) {
      debugPrint('OCR processing error: $e');
      rethrow;
    }
  }

  /// Preprocess image for better OCR results
  static Future<String> _preprocessImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // Decode image
      var image = img.decodeImage(bytes);
      if (image == null) return imagePath;

      // Apply preprocessing:
      // 1. Grayscale conversion
      image = img.grayscale(image);
      
      // 2. Contrast enhancement
      image = img.adjustColor(image, contrast: 1.2);
      
      // 3. Resize if too large (reduces processing time)
      const maxDimension = 2048;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: maxDimension);
        } else {
          image = img.copyResize(image, height: maxDimension);
        }
      }

      // Save processed image to temp file
      final tempDir = await Directory.systemTemp.createTemp('ocr_');
      final processedPath = '${tempDir.path}/processed.png';
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(img.encodePng(image));

      return processedPath;
    } catch (e) {
      debugPrint('Image preprocessing failed: $e');
      return imagePath;
    }
  }

  /// Convert ML Kit result to our OCRResult
  static OCRResult _convertToOCRResult(
    RecognizedText recognizedText,
    String imagePath,
    OCRScript? script,
  ) {
    final blocks = <TextBlock>[];

    for (final block in recognizedText.blocks) {
      final lines = <TextLine>[];

      for (final line in block.lines) {
        final words = <TextWord>[];

        for (final element in line.elements) {
          words.add(TextWord(
            text: element.text,
            boundingBox: _convertRect(element.boundingBox),
          ));
        }

        lines.add(TextLine(
          text: line.text,
          words: words,
          boundingBox: _convertRect(line.boundingBox),
        ));
      }

      blocks.add(TextBlock(
        text: block.text,
        lines: lines,
        boundingBox: _convertRect(block.boundingBox),
      ));
    }

    // Get image dimensions
    final imageFile = File(imagePath);
    final decoded = img.decodeImage(imageFile.readAsBytesSync());
    final width = decoded?.width ?? 0;
    final height = decoded?.height ?? 0;

    // Auto-detect script if not specified
    final detectedScript = script ?? _detectScript(recognizedText.text);

    return OCRResult(
      text: recognizedText.text,
      blocks: blocks,
      detectedScript: detectedScript,
      imageWidth: width,
      imageHeight: height,
    );
  }

  /// Convert Rect to BoundingBox
  static BoundingBox _convertRect(Rect rect) {
    return BoundingBox(
      left: rect.left.floor(),
      top: rect.top.floor(),
      right: rect.right.floor(),
      bottom: rect.bottom.floor(),
      width: rect.width.floor(),
      height: rect.height.floor(),
    );
  }

  /// Auto-detect script from text sample
  static OCRScript? _detectScript(String text) {
    if (text.isEmpty) return null;

    // Check for Devanagari (Hindi, Sanskrit, Marathi)
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      return OCRScript.devanagari;
    }

    // Check for Japanese
    if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(text)) {
      return OCRScript.japanese;
    }

    // Check for Korean
    if (RegExp(r'[\uAC00-\uD7AF\u1100-\u11FF]').hasMatch(text)) {
      return OCRScript.korean;
    }

    // Check for Chinese
    if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(text)) {
      return OCRScript.chinese;
    }

    // Default to Latin
    return OCRScript.latin;
  }

  /// Process multiple images and combine results
  static Future<OCRResult> processImages(
    List<String> imagePaths, {
    OCRScript? preferredScript,
  }) async {
    final results = <OCRResult>[];

    for (final path in imagePaths) {
      try {
        final result = await processImage(path, preferredScript: preferredScript);
        if (result.hasContent) {
          results.add(result);
        }
      } catch (e) {
        debugPrint('Failed to process image $path: $e');
      }
    }

    // Combine all texts
    final combinedText = results.map((r) => r.text).join('\n\n');
    final allBlocks = results.expand((r) => r.blocks).toList();

    // Average confidence
    final double avgConfidence = results.isEmpty
        ? 0.0
        : results.map((r) => r.confidence).reduce((a, b) => a + b) / results.length;

    return OCRResult(
      text: combinedText,
      blocks: allBlocks,
      confidence: avgConfidence,
      detectedScript: results.isNotEmpty ? results.first.detectedScript : null,
      imageWidth: results.isNotEmpty ? results.first.imageWidth : 0,
      imageHeight: results.isNotEmpty ? results.first.imageHeight : 0,
    );
  }

  /// Extract text from specific region of image
  static Future<String> extractRegion(
    String imagePath, 
    BoundingBox region, {
    OCRScript? script,
  }) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      var image = img.decodeImage(bytes);
      if (image == null) return '';

      // Crop to region
      final cropped = img.copyCrop(
        image,
        x: region.left,
        y: region.top,
        width: region.width,
        height: region.height,
      );

      // Save to temp file
      final tempDir = await Directory.systemTemp.createTemp('ocr_crop_');
      final tempPath = '${tempDir.path}/cropped.png';
      await File(tempPath).writeAsBytes(img.encodePng(cropped));

      // Process cropped image
      final result = await processImage(tempPath, preferredScript: script);

      // Cleanup
      await File(tempPath).delete();

      return result.text;
    } catch (e) {
      debugPrint('Region extraction failed: $e');
      return '';
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _textRecognizer?.close();
    _textRecognizer = null;
    _isInitialized = false;
  }
}
