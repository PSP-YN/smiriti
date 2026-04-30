import '../../core/services/embedding_service.dart';
import '../../core/services/llm_service.dart';
import '../../core/services/model_manager.dart';
import '../../data/models/objectbox_chunk.dart';
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
  static const int _maxChunks = 5;
  static const double _relevanceThreshold = 0.6;

  static Future<List<DocumentChunk>> retrieveRelevantChunks(
    String query, {
    int limit = _maxChunks,
    double threshold = _relevanceThreshold,
    List<String>? documentIds,
  }) async {
    // Generate query embedding
    final queryEmbedding = await EmbeddingService.embed(query);

    // Get all chunks with embeddings
    var allChunks = ObjectBoxStore.getAllChunksWithEmbeddings();

    // Filter by document IDs if specified
    if (documentIds != null && documentIds.isNotEmpty) {
      allChunks = allChunks.where((c) => documentIds.contains(c.documentId)).toList();
    }

    if (allChunks.isEmpty) return [];

    // Calculate cosine similarity for each chunk
    final scoredChunks = <_ScoredChunk>[];
    
    for (final chunk in allChunks) {
      if (chunk.embedding == null || chunk.embedding!.isEmpty) continue;
      
      final similarity = EmbeddingService.cosineSimilarity(
        queryEmbedding,
        chunk.embedding!,
      );
      
      if (similarity >= threshold) {
        scoredChunks.add(_ScoredChunk(chunk, similarity));
      }
    }

    // Sort by relevance and take top results
    scoredChunks.sort((a, b) => b.score.compareTo(a.score));
    final topChunks = scoredChunks.take(limit).toList();

    // Convert to domain entities
    return topChunks.map((scored) => DocumentChunk(
      id: scored.chunk.id.toString(),
      documentId: scored.chunk.documentId,
      content: scored.chunk.content,
      pageNumber: scored.chunk.pageNumber,
      position: scored.chunk.position,
      embedding: scored.chunk.embedding,
      createdAt: DateTime.parse(scored.chunk.createdAt),
    )).toList();
  }

  static Future<RAGResult> generateAnswer(
    String query, {
    List<DocumentChunk>? chunks,
    List<String>? documentIds,
  }) async {
    // Retrieve chunks if not provided
    final relevantChunks = chunks ?? await retrieveRelevantChunks(
      query,
      documentIds: documentIds,
    );

    if (relevantChunks.isEmpty) {
      return const RAGResult(
        answer: 'I could not find any relevant information in your documents to answer this question.',
        citations: [],
        confidence: 0.0,
      );
    }

    // Get document names for citations
    final citations = <Citation>[];
    final context = StringBuffer();
    
    for (var i = 0; i < relevantChunks.length; i++) {
      final chunk = relevantChunks[i];
      final doc = ObjectBoxStore.getDocument(chunk.documentId);
      final docName = doc?.name ?? 'Unknown Document';
      
      // Build context
      context.writeln('[${i + 1}] $docName, Page ${chunk.pageNumber}:');
      context.writeln(chunk.content);
      context.writeln();

      // Build citation
      citations.add(Citation(
        documentId: chunk.documentId,
        documentName: docName,
        pageNumber: chunk.pageNumber,
        content: chunk.content.substring(
          0,
          chunk.content.length > 200 ? 200 : chunk.content.length,
        ),
        relevanceScore: chunk.embedding != null ? 0.85 : 0.5,
      ));
    }

    // Check if LLM is available
    final activeModel = await ModelManager.getActiveModel();
    if (activeModel == null) {
      return _generatePlaceholderAnswer(query, relevantChunks, citations);
    }

    // Check if model is downloaded
    final isDownloaded = await ModelManager.isModelDownloaded(activeModel.id);
    if (!isDownloaded) {
      return _generatePlaceholderAnswer(query, relevantChunks, citations);
    }

    // Initialize LLM if needed
    if (!LLMService.isInitialized) {
      try {
        await LLMService.initialize();
      } catch (e) {
        return _generatePlaceholderAnswer(query, relevantChunks, citations);
      }
    }

    // Build context chunks for LLM
    final contextChunks = citations.map((c) => {
      'docName': c.documentName,
      'page': c.pageNumber,
      'content': c.content,
    }).toList();

    // Generate answer using LLM
    String answer;
    try {
      answer = await LLMService.generateWithRAG(
        query,
        contextChunks,
        maxTokens: 512,
        temperature: 0.7,
      );
    } catch (e) {
      // Fallback to placeholder if LLM fails
      answer = _generatePlaceholderAnswer(query, relevantChunks, citations);
    }
    
    // Calculate confidence based on number and quality of chunks
    final avgScore = citations.map((c) => c.relevanceScore).reduce((a, b) => a + b) / citations.length;
    final confidence = avgScore * (citations.length / _maxChunks).clamp(0.5, 1.0);

    return RAGResult(
      answer: answer,
      citations: citations,
      confidence: confidence,
    );
  }

  static RAGResult _generatePlaceholderAnswer(
    String query,
    List<DocumentChunk> chunks,
    List<Citation> citations,
  ) {
    // Fallback when LLM is not available
    final buffer = StringBuffer();
    buffer.writeln('Based on your documents, here is what I found:');
    buffer.writeln();
    buffer.writeln('Relevant content found in:');
    
    for (final citation in citations) {
      buffer.writeln('• ${citation.documentName}, Page ${citation.pageNumber}');
    }
    
    if (chunks.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Preview of relevant text:');
      final preview = chunks.first.content.length > 150 
          ? '${chunks.first.content.substring(0, 150)}...'
          : chunks.first.content;
      buffer.writeln('"$preview"');
    }
    
    buffer.writeln();
    buffer.writeln('(Download an LLM model in Settings for AI-powered answers)');

    // Calculate confidence based on citations
    final avgScore = citations.isNotEmpty
        ? citations.map((c) => c.relevanceScore).reduce((a, b) => a + b) / citations.length
        : 0.0;

    return RAGResult(
      answer: buffer.toString(),
      citations: citations,
      confidence: avgScore,
    );
  }

  static Future<void> indexDocument(Document document, List<String> extractedText) async {
    // Store document in ObjectBox
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

    // Chunk the document
    final chunks = _createChunks(document.id, extractedText);

    // Generate embeddings for chunks
    final texts = chunks.map((c) => c.content).toList();
    final embeddings = await EmbeddingService.embedBatch(texts);

    // Update chunks with embeddings and store
    for (var i = 0; i < chunks.length; i++) {
      chunks[i].embedding = embeddings[i];
    }

    ObjectBoxStore.insertChunks(chunks);
  }

  static List<ObjectBoxChunk> _createChunks(String documentId, List<String> extractedText) {
    const int chunkSize = 500; // approximate word count
    const int overlap = 50;
    
    final chunks = <ObjectBoxChunk>[];
    var chunkIndex = 0;

    for (var pageIndex = 0; pageIndex < extractedText.length; pageIndex++) {
      final pageText = extractedText[pageIndex];
      if (pageText.trim().isEmpty) continue;

      final words = pageText.split(' ');
      var currentChunk = <String>[];
      var currentWordCount = 0;

      for (var i = 0; i < words.length; i++) {
        currentChunk.add(words[i]);
        currentWordCount++;

        if (currentWordCount >= chunkSize || i == words.length - 1) {
          chunks.add(ObjectBoxChunk(
            documentId: documentId,
            content: currentChunk.join(' '),
            pageNumber: pageIndex + 1,
            position: chunkIndex,
            createdAt: DateTime.now().toIso8601String(),
          ));

          chunkIndex++;

          // Apply overlap for next chunk
          if (i < words.length - 1) {
            final overlapStart = (currentChunk.length - overlap).clamp(0, currentChunk.length);
            currentChunk = currentChunk.sublist(overlapStart);
            currentWordCount = currentChunk.length;
          }
        }
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
