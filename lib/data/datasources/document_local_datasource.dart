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
  Future<List<String>> extractTextFromPdf(String filePath);
  Future<List<String>> extractTextFromTxt(String filePath);
  Future<List<String>> extractTextFromImage(String filePath);
  Future<List<String>> extractTextFromAudio(String filePath);
}

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  final SharedPreferences _prefs;

  DocumentLocalDataSourceImpl(this._prefs);

  @override
  Future<List<Document>> getAllDocuments() async {
    final jsonString = _prefs.getString(AppConstants.documentsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Document.fromJson(json)).toList();
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    final documents = await getAllDocuments();
    try {
      return documents.firstWhere((doc) => doc.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Document> saveDocument(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final documentsDir = Directory('${appDir.path}/documents');
    if (!await documentsDir.exists()) {
      await documentsDir.create(recursive: true);
    }

    final fileName = file.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newFileName = '${id}_$fileName';
    final newPath = '${documentsDir.path}/$newFileName';

    await file.copy(newPath);

    int pageCount = 0;
    List<String> extractedText = [];

    if (extension == 'pdf') {
      extractedText = await extractTextFromPdf(newPath);
      pageCount = extractedText.length;
    } else if (extension == 'txt') {
      extractedText = await extractTextFromTxt(newPath);
      pageCount = 1;
    } else if (['jpg', 'jpeg', 'png', 'webp', 'bmp'].contains(extension)) {
      extractedText = await extractTextFromImage(newPath);
      pageCount = 1;
    } else if (['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'].contains(extension)) {
      extractedText = await extractTextFromAudio(newPath);
      pageCount = 1;
    }

    final document = Document(
      id: id,
      name: fileName,
      path: newPath,
      type: extension,
      createdAt: DateTime.now(),
      pageCount: pageCount,
      extractedText: extractedText,
    );

    final documents = await getAllDocuments();
    documents.add(document);
    await _saveDocuments(documents);

    return document;
  }

  @override
  Future<void> deleteDocument(String id) async {
    // Delete from SharedPreferences
    final documents = await getAllDocuments();
    final docIndex = documents.indexWhere((doc) => doc.id == id);
    
    if (docIndex != -1) {
      final doc = documents[docIndex];
      final file = File(doc.path);
      if (await file.exists()) {
        await file.delete();
      }
      documents.removeAt(docIndex);
      await _saveDocuments(documents);
    }
    
    // Delete from ObjectBox (including chunks)
    ObjectBoxStore.deleteDocument(id);
  }

  @override
  Future<void> saveDocumentChunks(
    String documentId,
    List<DocumentChunk> chunks,
  ) async {
    final chunksJson = chunks.map((c) => c.toJson()).toList();
    await _prefs.setString(
      'chunks_$documentId',
      json.encode(chunksJson),
    );
  }

  @override
  Future<List<DocumentChunk>> getDocumentChunks(String documentId) async {
    final jsonString = _prefs.getString('chunks_$documentId');
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => DocumentChunk.fromJson(json)).toList();
  }

  @override
  Future<List<String>> extractTextFromPdf(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final List<String> pages = [];

      // Create extractor once for the document
      final textExtractor = PdfTextExtractor(document);

      for (var i = 0; i < document.pages.count; i++) {
        final text = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
        pages.add(text);
      }

      document.dispose();
      return pages;
    } catch (e) {
      return ['Error extracting PDF: $e'];
    }
  }

  @override
  Future<List<String>> extractTextFromTxt(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      return [content];
    } catch (e) {
      return ['Error reading text file: $e'];
    }
  }

  @override
  Future<List<String>> extractTextFromImage(String filePath) async {
    try {
      // Initialize OCR if needed
      await OCRService.initialize();
      
      // Process image with OCR
      final result = await OCRService.processImage(filePath);
      
      if (result.hasContent) {
        return [result.text];
      } else {
        return ['No text detected in image'];
      }
    } catch (e) {
      return ['Error processing image: $e'];
    }
  }

  @override
  Future<List<String>> extractTextFromAudio(String filePath) async {
    try {
      // Initialize transcription service
      await AudioTranscriptionService.initialize();
      
      // Transcribe audio
      final result = await AudioTranscriptionService.transcribe(filePath);
      
      if (result.text.isNotEmpty) {
        return [result.text];
      } else {
        return ['No speech detected in audio'];
      }
    } catch (e) {
      return ['Error transcribing audio: $e'];
    }
  }

  Future<void> _saveDocuments(List<Document> documents) async {
    final jsonList = documents.map((d) => d.toJson()).toList();
    await _prefs.setString(AppConstants.documentsKey, json.encode(jsonList));
  }
}
