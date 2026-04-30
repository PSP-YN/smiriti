import 'dart:io';

import '../../core/services/embedding_service.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_chunk.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/services/rag_orchestrator.dart';
import '../datasources/document_local_datasource.dart';
import '../models/objectbox_document.dart';
import '../models/objectbox_chunk.dart';
import '../objectbox_store.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource _localDataSource;

  DocumentRepositoryImpl(this._localDataSource);

  @override
  Future<List<Document>> getAllDocuments() async {
    final obDocs = ObjectBoxStore.getAllDocuments();
    return obDocs.map((obDoc) => _toDocument(obDoc)).toList();
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    final obDoc = ObjectBoxStore.getDocument(id);
    if (obDoc == null) return null;
    return _toDocument(obDoc);
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
  Future<Document> addDocument(File file) {
    return _localDataSource.saveDocument(file);
  }

  @override
  Future<void> deleteDocument(String id) {
    return _localDataSource.deleteDocument(id);
  }

  @override
  Future<List<String>> extractTextFromDocument(Document document) async {
    switch (document.type.toLowerCase()) {
      case 'pdf':
        return _localDataSource.extractTextFromPdf(document.path);
      case 'txt':
        return _localDataSource.extractTextFromTxt(document.path);
      default:
        return [];
    }
  }

  @override
  Future<List<DocumentChunk>> chunkDocument(
    Document document,
    List<String> extractedText,
  ) async {
    if (!EmbeddingService.isInitialized) {
      throw StateError('Embedding service not initialized. Please download the model first.');
    }

    await RAGOrchestrator.indexDocument(document, extractedText);

    // Return chunks from ObjectBox
    final obChunks = ObjectBoxStore.getChunksForDocument(document.id);
    return obChunks.map((obChunk) => DocumentChunk(
      id: obChunk.id.toString(),
      documentId: obChunk.documentId,
      content: obChunk.content,
      pageNumber: obChunk.pageNumber,
      position: obChunk.position,
      embedding: obChunk.embedding,
      createdAt: DateTime.parse(obChunk.createdAt),
    )).toList();
  }

  @override
  Future<List<DocumentChunk>> searchSimilarChunks(
    String query, {
    int limit = 5,
  }) async {
    if (!EmbeddingService.isInitialized) {
      // Fallback to keyword search if embeddings not available
      return _keywordSearch(query, limit);
    }

    return RAGOrchestrator.retrieveRelevantChunks(query, limit: limit);
  }

  Future<List<DocumentChunk>> _keywordSearch(String query, int limit) async {
    final queryWords = query.toLowerCase().split(' ');
    final allChunks = ObjectBoxStore.chunkBox.getAll();
    
    final scoredChunks = <_ScoredChunk>[];
    
    for (final chunk in allChunks) {
      final contentLower = chunk.content.toLowerCase();
      int matches = 0;
      for (final word in queryWords) {
        if (contentLower.contains(word)) {
          matches++;
        }
      }
      final score = matches / queryWords.length;
      if (score > 0) {
        scoredChunks.add(_ScoredChunk(chunk, score));
      }
    }
    
    scoredChunks.sort((a, b) => b.score.compareTo(a.score));
    
    return scoredChunks.take(limit).map((sc) => DocumentChunk(
      id: sc.chunk.id.toString(),
      documentId: sc.chunk.documentId,
      content: sc.chunk.content,
      pageNumber: sc.chunk.pageNumber,
      position: sc.chunk.position,
      embedding: sc.chunk.embedding,
      createdAt: DateTime.parse(sc.chunk.createdAt),
    )).toList();
  }
}

class _ScoredChunk {
  final ObjectBoxChunk chunk;
  final double score;

  _ScoredChunk(this.chunk, this.score);
}
