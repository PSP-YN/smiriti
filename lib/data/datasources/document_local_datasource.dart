import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/audio_transcription_service.dart';
import '../../core/services/ocr_service.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_chunk.dart';
import '../objectbox_store.dart';

abstract class DocumentLocalDataSource {
  Future<List<Document>> getAllDocuments();
  Future<Document?> getDocumentById(String id);
  Future<Document> saveDocument(File file);
  Future<void> deleteDocument(String id);
  Future<void> saveDocumentChunks(String documentId, List<DocumentChunk> chunks);
  Future<List<DocumentChunk>> getDocumentChunks(String documentId);
}

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  final SharedPreferences _prefs;

  DocumentLocalDataSourceImpl(this._prefs);

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Future<List<Document>> getAllDocuments() async {
    final json = _prefs.getString(AppConstants.documentsKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((j) => Document.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    final docs = await getAllDocuments();
    try {
      return docs.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<Document> saveDocument(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${appDir.path}/documents');
    if (!await docsDir.exists()) await docsDir.create(recursive: true);

    final origName = file.path.split('/').last;
    final extension = origName.contains('.')
        ? origName.split('.').last.toLowerCase()
        : 'bin';
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final destPath = '${docsDir.path}/${id}_$origName';

    await file.copy(destPath);

    // ── Text extraction ────────────────────────────────────────────────────
    final List<String> extractedText;
    int pageCount;

    if (AppConstants.documentExtensions.contains(extension)) {
      if (extension == 'pdf') {
        extractedText = await _extractPdf(destPath);
      } else {
        extractedText = await _extractTxt(destPath);
      }
      pageCount = extractedText.length;
    } else if (AppConstants.imageExtensions.contains(extension)) {
      extractedText = await _extractImage(destPath);
      pageCount = 1;
    } else if (AppConstants.audioExtensions.contains(extension)) {
      extractedText = await _extractAudio(destPath);
      pageCount = 1;
    } else if (AppConstants.videoExtensions.contains(extension)) {
      // For video, extract audio track and transcribe
      extractedText = await _extractAudio(destPath);
      pageCount = 1;
    } else {
      extractedText = [];
      pageCount = 0;
    }

    final document = Document(
      id: id,
      name: origName,
      path: destPath,
      type: extension,
      createdAt: DateTime.now(),
      pageCount: pageCount,
      extractedText: extractedText,
    );

    // Persist metadata
    final docs = await getAllDocuments();
    docs.add(document);
    await _persistDocuments(docs);

    return document;
  }

  @override
  Future<void> deleteDocument(String id) async {
    final docs = await getAllDocuments();
    final idx = docs.indexWhere((d) => d.id == id);
    if (idx != -1) {
      final file = File(docs[idx].path);
      if (await file.exists()) await file.delete();
      docs.removeAt(idx);
      await _persistDocuments(docs);
    }
    ObjectBoxStore.deleteDocument(id);
  }

  // ── Chunks ────────────────────────────────────────────────────────────────

  @override
  Future<void> saveDocumentChunks(
      String documentId, List<DocumentChunk> chunks) async {
    await _prefs.setString(
      'chunks_$documentId',
      jsonEncode(chunks.map((c) => c.toJson()).toList()),
    );
  }

  @override
  Future<List<DocumentChunk>> getDocumentChunks(String documentId) async {
    final json = _prefs.getString('chunks_$documentId');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((j) => DocumentChunk.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Private extraction helpers ────────────────────────────────────────────

  Future<List<String>> _extractPdf(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(doc);
      final pages = <String>[];
      for (var i = 0; i < doc.pages.count; i++) {
        final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        if (text.trim().isNotEmpty) pages.add(text);
      }
      doc.dispose();
      return pages;
    } catch (e) {
      return ['[PDF extraction error: $e]'];
    }
  }

  Future<List<String>> _extractTxt(String path) async {
    try {
      final content = await File(path).readAsString();
      return [content];
    } catch (e) {
      return ['[Text file error: $e]'];
    }
  }

  Future<List<String>> _extractImage(String path) async {
    try {
      await OCRService.initialize();
      final result = await OCRService.processImage(path, preprocess: true);
      return result.hasContent ? [result.text] : ['[No text detected in image]'];
    } catch (e) {
      return ['[OCR error: $e]'];
    }
  }

  Future<List<String>> _extractAudio(String path) async {
    try {
      await AudioTranscriptionService.initialize();
      final result = await AudioTranscriptionService.transcribe(path);
      return result.text.isNotEmpty
          ? [result.text]
          : ['[No speech detected in audio]'];
    } catch (e) {
      return ['[Audio transcription error: $e]'];
    }
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _persistDocuments(List<Document> docs) async {
    await _prefs.setString(
      AppConstants.documentsKey,
      jsonEncode(docs.map((d) => d.toJson()).toList()),
    );
  }
}
