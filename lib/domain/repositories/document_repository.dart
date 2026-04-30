import 'dart:io';

import '../entities/document.dart';
import '../entities/document_chunk.dart';

abstract class DocumentRepository {
  Future<List<Document>> getAllDocuments();
  Future<Document?> getDocumentById(String id);
  Future<Document> addDocument(File file);
  Future<void> deleteDocument(String id);
  
  Future<List<String>> extractTextFromDocument(Document document);
  Future<List<DocumentChunk>> chunkDocument(Document document, List<String> extractedText);
  
  Future<List<DocumentChunk>> searchSimilarChunks(
    String query, {
    int limit = 5,
  });
}
