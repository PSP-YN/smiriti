import 'dart:io';

import '../../core/services/embedding_service.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_chunk.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/services/rag_orchestrator.dart';
import '../datasources/document_local_datasource.dart';
import '../models/objectbox_chunk.dart';
import '../objectbox_store.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource _localDataSource;

  DocumentRepositoryImpl(this._localDataSource);

  @override
  Future<List<Document>> getAllDocuments() async {
    return _localDataSource.getAllDocuments();
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    return _localDataSource.getDocumentById(id);
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
    return document.extractedText;
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

    final obChunks = ObjectBoxStore.getChunksForDocument(document.id);
    return obChunks.map((obChunk) => DocumentChunk(
      id: obChunk.id.toString(),
      documentId: obChunk.documentId,
      content: obChunk.content,
      pageNumber: obChunk.pageNumber,
      position: obChunk.position,
      embedding: obChunk.embeddingFloats,
      createdAt: DateTime.parse(obChunk.createdAt),
    )).toList();
  }

  @override
  Future<List<DocumentChunk>> searchSimilarChunks(
    String query, {
    int limit = 5,
  }) async {
    if (!EmbeddingService.isInitialized) {
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
      embedding: sc.chunk.embeddingFloats,
      createdAt: DateTime.parse(sc.chunk.createdAt),
    )).toList();
  }
}

class _ScoredChunk {
  final ObjectBoxChunk chunk;
  final double score;

  _ScoredChunk(this.chunk, this.score);
}
