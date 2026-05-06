import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';

class SummarizePage extends StatefulWidget {
  final String? documentId;

  const SummarizePage({super.key, this.documentId});

  @override
  State<SummarizePage> createState() => _SummarizePageState();
}

class _SummarizePageState extends State<SummarizePage> {
  final _repository = GetIt.I<DocumentRepository>();
  Document? _selectedDocument;
  List<Document> _documents = [];
  String _summary = '';
  bool _isLoading = false;
  String _summaryType = 'concise';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final docs = await _repository.getAllDocuments();
    if (mounted) {
      setState(() {
        _documents = docs;
        if (widget.documentId != null) {
          try {
            _selectedDocument = docs.firstWhere((d) => d.id == widget.documentId);
          } catch (_) {
            _selectedDocument = docs.isNotEmpty ? docs.first : null;
          }
        } else {
          _selectedDocument = docs.isNotEmpty ? docs.first : null;
        }
      });
    }
  }

  Future<void> _generateSummary() async {
    if (_selectedDocument == null) return;

    setState(() {
      _isLoading = true;
      _summary = '';
    });

    try {
      // Placeholder summaries until LLM integration is active.
      // When an LLM model is downloaded, this path will be replaced
      // by RAGOrchestrator.generateAnswer() with a summarization prompt.
      await Future.delayed(const Duration(milliseconds: 800));

      final name = _selectedDocument!.name;
      final pages = _selectedDocument!.pageCount;

      final summary = switch (_summaryType) {
        'concise' => '''Summary of "$name"

This $pages-page document has been indexed for search. Key topics from the document are available for AI-powered Q&A in the Chat tab.

Key Points:
• Document indexed and ready for queries
• Use Chat to ask specific questions
• Full AI summaries require an LLM model download

(Download an AI model in Settings → AI Models for full summaries)''',
        'detailed' => '''Detailed Summary of "$name"

Document Information:
• Pages: $pages
• Type: ${_selectedDocument!.type.toUpperCase()}
• Status: Indexed and searchable

This document has been fully processed and chunked into semantic segments. All content is searchable via the Chat feature using natural language queries.

To get a real AI-generated detailed summary, download a language model from Settings → AI Models, then return here.''',
        'bullet_points' => '''Key Points from "$name":

• $pages ${pages == 1 ? 'page' : 'pages'} of content, fully indexed
• All text extracted and embedded for semantic search
• Queryable from the Chat screen using natural language
• Supports cross-document search when multiple docs are loaded

To extract AI-powered bullet points, download an LLM from Settings → AI Models.''',
        _ => 'Select a summary type above.',
      };

      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summary = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _summary));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summarize'),
        centerTitle: true,
        actions: [
          if (_summary.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              onPressed: _copyToClipboard,
              tooltip: 'Copy to clipboard',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document selector
            if (_documents.length > 1) ...[
              DropdownButtonFormField<Document>(
                value: _selectedDocument,
                decoration: const InputDecoration(
                  labelText: 'Document',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _documents.map((doc) => DropdownMenuItem(
                  value: doc,
                  child: Text(doc.name, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (doc) => setState(() {
                  _selectedDocument = doc;
                  _summary = '';
                }),
              ),
              const SizedBox(height: 16),
            ],

            // Summary type selector
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'concise',
                  label: Text('Concise'),
                  icon: Icon(Icons.short_text),
                ),
                ButtonSegment(
                  value: 'detailed',
                  label: Text('Detailed'),
                  icon: Icon(Icons.subject),
                ),
                ButtonSegment(
                  value: 'bullet_points',
                  label: Text('Bullet'),
                  icon: Icon(Icons.format_list_bulleted),
                ),
              ],
              selected: {_summaryType},
              onSelectionChanged: (selected) => setState(() {
                _summaryType = selected.first;
                _summary = '';
              }),
            ),

            const SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _selectedDocument == null || _isLoading
                    ? null
                    : _generateSummary,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'Generating...' : 'Generate Summary'),
              ),
            ),

            const SizedBox(height: 20),

            // Summary output
            if (_summary.isNotEmpty)
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Summary',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          _summary,
                          style: const TextStyle(fontSize: 14, height: 1.65),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (_documents.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Add documents from the home screen\nto generate summaries.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
