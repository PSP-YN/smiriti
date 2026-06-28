import '../../core/constants/app_constants.dart';
import '../../core/services/embedding_service.dart';
import '../../core/services/llm_service.dart';
import '../../core/services/model_manager.dart';
import '../../data/models/objectbox_chunk.dart';
import '../../data/models/objectbox_document.dart';
import '../../data/objectbox_store.dart';
import '../entities/document.dart';
import '../entities/document_chunk.dart';

class RAGResult {
  final String answer;
  final List<Citation> citations;
  final double confidence;

  const RAGResult({
    required this.answer,
    required this.citations,
    required this.confidence,
  });
}

class Citation {
  final String documentId;
  final String documentName;
  final int pageNumber;
  final String content;
  final double relevanceScore;

  const Citation({
    required this.documentId,
    required this.documentName,
    required this.pageNumber,
    required this.content,
    required this.relevanceScore,
  });
}

class RAGOrchestrator {
  RAGOrchestrator._();

  static const int _maxChunks = AppConstants.maxRetrievedChunks;
  static const double _relevanceThreshold = 0.45;

  static Future<List<DocumentChunk>> retrieveRelevantChunks(
    String query, {
    int limit = _maxChunks,
    double threshold = _relevanceThreshold,
    List<String>? documentIds,
    String? notebookId,
  }) async {
    final queryEmbedding = await EmbeddingService.embed(query);
    var allChunks = ObjectBoxStore.getAllChunksWithEmbeddings();

    if (documentIds != null && documentIds.isNotEmpty) {
      allChunks = allChunks
          .where((c) => documentIds.contains(c.documentId))
          .toList();
    } else if (notebookId != null) {
      final notebookDocIds = ObjectBoxStore.getAllDocuments()
          .where((d) => d.notebookId == notebookId)
          .map((d) => d.documentId)
          .toList();
      allChunks = allChunks
          .where((c) => notebookDocIds.contains(c.documentId))
          .toList();
    }

    if (allChunks.isEmpty) return [];

    final vectorResults = <_ScoredChunk>[];
    for (final chunk in allChunks) {
      final embedding = chunk.embeddingFloats;
      if (embedding == null || embedding.isEmpty) continue;
      final similarity =
          EmbeddingService.cosineSimilarity(queryEmbedding, embedding);
      if (similarity >= threshold) {
        vectorResults.add(_ScoredChunk(chunk, similarity));
      }
    }

    final keywordResults = _keywordSearch(query, allChunks);

    final fusedChunks = _reciprocalRankFusion(vectorResults, keywordResults);

    fusedChunks.sort((a, b) => b.score.compareTo(a.score));
    final topChunks = fusedChunks.take(limit).toList();

    return topChunks
        .map((sc) => DocumentChunk(
              id: sc.chunk.id.toString(),
              documentId: sc.chunk.documentId,
              content: sc.chunk.content,
              pageNumber: sc.chunk.pageNumber,
              position: sc.chunk.position,
              embedding: sc.chunk.embeddingFloats,
              createdAt: DateTime.parse(sc.chunk.createdAt),
            ))
        .toList();
  }

  static List<_ScoredChunk> _keywordSearch(String query, List<ObjectBoxChunk> chunks) {
    final results = <_ScoredChunk>[];
    final queryTerms = query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 2).toList();

    if (queryTerms.isEmpty) return [];

    for (final chunk in chunks) {
      final content = chunk.content.toLowerCase();
      double score = 0;
      for (final term in queryTerms) {
        if (content.contains(term)) {
          score += 1.0;
        }
      }
      if (score > 0) {
        results.add(_ScoredChunk(chunk, score / queryTerms.length));
      }
    }
    return results;
  }

  static List<_ScoredChunk> _reciprocalRankFusion(
      List<_ScoredChunk> vector, List<_ScoredChunk> keyword) {
    final Map<int, _ScoredChunk> map = {};

    for (final sc in vector) {
      map[sc.chunk.id] = _ScoredChunk(sc.chunk, sc.score * 0.7);
    }

    for (final sc in keyword) {
      if (map.containsKey(sc.chunk.id)) {
        map[sc.chunk.id] = _ScoredChunk(sc.chunk, map[sc.chunk.id]!.score + (sc.score * 0.3));
      } else {
        map[sc.chunk.id] = _ScoredChunk(sc.chunk, sc.score * 0.3);
      }
    }

    return map.values.toList();
  }

  static Future<RAGResult> generateAnswer(
    String query, {
    List<DocumentChunk>? chunks,
    List<String>? documentIds,
  }) async {
    final relevantChunks = chunks ??
        await retrieveRelevantChunks(query, documentIds: documentIds);

    if (relevantChunks.isEmpty) {
      return const RAGResult(
        answer:
            'I could not find any relevant information in your documents to answer this question. '
            'Please try rephrasing or add more documents.',
        citations: [],
        confidence: 0.0,
      );
    }

    final citations = <Citation>[];
    final contextBuf = StringBuffer();

    for (var i = 0; i < relevantChunks.length; i++) {
      final chunk = relevantChunks[i];
      final doc = ObjectBoxStore.getDocument(chunk.documentId);
      final docName = doc?.name ?? 'Unknown Document';
      final score = chunk.embedding != null ? 0.85 : 0.5;

      contextBuf
        ..writeln('[${i + 1}] "$docName", Page ${chunk.pageNumber}:')
        ..writeln(chunk.content)
        ..writeln();

      citations.add(Citation(
        documentId: chunk.documentId,
        documentName: docName,
        pageNumber: chunk.pageNumber,
        content: chunk.content.length > 300
            ? '${chunk.content.substring(0, 300)}…'
            : chunk.content,
        relevanceScore: score,
      ));
    }

    final activeModel = await ModelManager.getActiveModel();
    final isDownloaded =
        activeModel != null && await ModelManager.isModelDownloaded(activeModel.id);

    if (!isDownloaded) {
      return _placeholderAnswer(query, relevantChunks, citations);
    }

    if (!LLMService.isInitialized) {
      try {
        await LLMService.initialize();
      } catch (_) {
        return _placeholderAnswer(query, relevantChunks, citations);
      }
    }

    final contextChunks = citations
        .map((c) => {
              'docName': c.documentName,
              'page': c.pageNumber,
              'content': c.content,
            })
        .toList();

    String answer;
    try {
      answer = await LLMService.generateWithRAG(
        query,
        contextChunks,
        maxTokens: AppConstants.llmMaxTokens,
        temperature: AppConstants.llmTemperature,
      );
    } catch (_) {
      return _placeholderAnswer(query, relevantChunks, citations);
    }

    final avgScore =
        citations.map((c) => c.relevanceScore).reduce((a, b) => a + b) /
            citations.length;
    final coverage = (citations.length / _maxChunks).clamp(0.5, 1.0);
    final confidence = avgScore * coverage;

    return RAGResult(answer: answer, citations: citations, confidence: confidence);
  }

  static RAGResult _placeholderAnswer(
    String query,
    List<DocumentChunk> chunks,
    List<Citation> citations,
  ) {
    final buf = StringBuffer();
    buf.writeln('Here is what I found in your documents:\n');

    for (var i = 0; i < citations.length; i++) {
      final c = citations[i];
      buf.writeln('[${i + 1}] "${c.documentName}", Page ${c.pageNumber}:');
      buf.writeln(c.content);
      buf.writeln();
    }

    buf.writeln('─────────────────────────────');
    buf.writeln(
        'Download an LLM model in Settings → AI Models for AI-generated answers.');

    final avgScore = citations.isNotEmpty
        ? citations.map((c) => c.relevanceScore).reduce((a, b) => a + b) /
            citations.length
        : 0.0;

    return RAGResult(
        answer: buf.toString(), citations: citations, confidence: avgScore);
  }

  static Future<void> indexDocument(
      Document document, List<String> extractedText) async {
    if (document.extractedText.isNotEmpty) {
      ObjectBoxStore.insertDocument(ObjectBoxDocument(
        documentId: document.id,
        name: document.name,
        path: document.path,
        type: document.type,
        createdAt: document.createdAt.toIso8601String(),
        pageCount: document.pageCount,
        thumbnailPath: document.thumbnailPath,
        notebookId: null,
      ));
    }

    final chunks = _createChunks(document.id, extractedText);
    if (chunks.isEmpty) return;

    final texts = chunks.map((c) => c.content).toList();
    final embeddings = await EmbeddingService.embedBatch(texts);

    for (var i = 0; i < chunks.length; i++) {
      if (i < embeddings.length) {
        chunks[i].embeddingFloats = embeddings[i];
      }
    }

    ObjectBoxStore.insertChunks(chunks);
  }

  static List<ObjectBoxChunk> _createChunks(
      String documentId, List<String> pages) {
    const chunkSize = AppConstants.chunkSizeWords;
    const overlap = AppConstants.chunkOverlapWords;

    final chunks = <ObjectBoxChunk>[];
    var chunkIndex = 0;

    for (var pageIdx = 0; pageIdx < pages.length; pageIdx++) {
      final pageText = pages[pageIdx].trim();
      if (pageText.isEmpty) continue;

      final words = pageText.split(RegExp(r'\s+'));
      var start = 0;

      while (start < words.length) {
        final end = (start + chunkSize).clamp(0, words.length);
        final content = words.sublist(start, end).join(' ');

        if (content.trim().isNotEmpty) {
          chunks.add(ObjectBoxChunk(
            documentId: documentId,
            content: content,
            pageNumber: pageIdx + 1,
            position: chunkIndex++,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }

        if (end == words.length) break;
        start = end - overlap;
        if (start < 0) start = 0;
      }
    }

    return chunks;
  }

  static Future<void> deleteDocumentIndex(String documentId) async {
    ObjectBoxStore.deleteDocument(documentId);
  }
}

class _ScoredChunk {
  final ObjectBoxChunk chunk;
  final double score;
  _ScoredChunk(this.chunk, this.score);
}
