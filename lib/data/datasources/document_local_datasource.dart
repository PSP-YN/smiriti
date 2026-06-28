import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/audio_transcription_service.dart';
import '../../core/services/ocr_service.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_chunk.dart';
import '../models/objectbox_document.dart';
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
  DocumentLocalDataSourceImpl();

  @override
  Future<List<Document>> getAllDocuments() async {
    final obDocs = ObjectBoxStore.getAllDocuments();
    return obDocs.map(_toDocument).toList();
  }

  Document _toDocument(ObjectBoxDocument obDoc) {
    return Document(
      id: obDoc.documentId,
      name: obDoc.name,
      path: obDoc.path,
      type: obDoc.type,
      createdAt: DateTime.parse(obDoc.createdAt),
      pageCount: obDoc.pageCount,
      thumbnailPath: obDoc.thumbnailPath,
    );
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    final obDoc = ObjectBoxStore.getDocument(id);
    if (obDoc == null) return null;
    return _toDocument(obDoc);
  }

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

    final obDoc = ObjectBoxDocument(
      documentId: document.id,
      name: document.name,
      path: document.path,
      type: document.type,
      createdAt: document.createdAt.toIso8601String(),
      pageCount: document.pageCount,
      thumbnailPath: document.thumbnailPath,
    );
    ObjectBoxStore.insertDocument(obDoc);

    return document;
  }

  @override
  Future<void> deleteDocument(String id) async {
    final doc = ObjectBoxStore.getDocument(id);
    if (doc != null) {
      final file = File(doc.path);
      if (await file.exists()) await file.delete();
    }
    ObjectBoxStore.deleteDocument(id);
  }

  @override
  Future<void> saveDocumentChunks(
      String documentId, List<DocumentChunk> chunks) async {
    // Chunks are stored directly via ObjectBoxStore in RAGOrchestrator
  }

  @override
  Future<List<DocumentChunk>> getDocumentChunks(String documentId) async {
    final obChunks = ObjectBoxStore.getChunksForDocument(documentId);
    return obChunks.map((c) => DocumentChunk(
      id: c.id.toString(),
      documentId: c.documentId,
      content: c.content,
      pageNumber: c.pageNumber,
      position: c.position,
      embedding: c.embeddingFloats,
      createdAt: DateTime.parse(c.createdAt),
    )).toList();
  }

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
}
