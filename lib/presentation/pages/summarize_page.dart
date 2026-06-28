import 'package:flutter/material.dart';

import '../../core/services/embedding_service.dart';
import '../../core/services/llm_service.dart';
import '../../domain/services/rag_orchestrator.dart';
import '../../data/objectbox_store.dart';

class SummarizePage extends StatefulWidget {
  const SummarizePage({super.key});

  @override
  State<SummarizePage> createState() => _SummarizePageState();
}

class _SummarizePageState extends State<SummarizePage> {
  String _summary = '';
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _summarize();
  }

  Future<void> _summarize() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _summary = '';
    });

    try {
      final notes = ObjectBoxStore.getAllNotes();
      if (notes.isEmpty) {
        setState(() {
          _isLoading = false;
          _summary = 'No notes to summarize. Create some notes first.';
        });
        return;
      }

      final allText = notes.map((n) => '${n.title}: ${n.content}').join('\n\n');
      final truncated = allText.length > 8000 ? '${allText.substring(0, 8000)}...' : allText;

      final llmReady = LLMService.isInitialized;
      final embeddingReady = EmbeddingService.isInitialized;

      if (llmReady || embeddingReady) {
        final result = await RAGOrchestrator.generateAnswer(
          'Summarize the following notes concisively, highlighting the main points:\n\n$truncated',
        );
        setState(() {
          _summary = result.answer;
          _isLoading = false;
        });
      } else {
        // Keyword-based fallback summary
        final words = allText.split(RegExp(r'\s+'));
        final wordFreq = <String, int>{};
        for (final w in words) {
          final clean = w.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
          if (clean.length > 3 && !_stopWords.contains(clean)) {
            wordFreq[clean] = (wordFreq[clean] ?? 0) + 1;
          }
        }
        final sorted = wordFreq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final topTopics = sorted.take(5).map((e) => e.key).join(', ');

        setState(() {
          _isLoading = false;
          _summary = allText.length > 2000
              ? 'You have ${notes.length} note(s) with ${words.length} total words.\n\n'
                  '**Key topics**: $topTopics\n\n'
                  '${allText.substring(0, 2000)}...\n\n'
                  'Install a local LLM model for AI-powered summaries.'
              : allText;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  static const _stopWords = {
    'this', 'that', 'with', 'from', 'have', 'been', 'were', 'they', 'their',
    'what', 'when', 'where', 'which', 'there', 'about', 'would', 'could',
    'should', 'also', 'than', 'then', 'into', 'more', 'some', 'such', 'just',
    'because', 'these', 'those', 'while',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summarize Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _summary.isNotEmpty ? _summarize : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _summarize, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _summary,
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),
                    ],
                  ),
                ),
    );
  }
}
