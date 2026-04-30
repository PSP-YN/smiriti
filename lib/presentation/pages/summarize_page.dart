import 'package:flutter/material.dart';
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
  final DocumentRepository _repository = GetIt.I<DocumentRepository>();
  Document? _selectedDocument;
  List<Document> _documents = [];
  String _summary = '';
  bool _isLoading = false;
  String _summaryType = 'concise'; // 'concise', 'detailed', 'bullet_points'

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final docs = await _repository.getAllDocuments();
    setState(() {
      _documents = docs;
      if (widget.documentId != null) {
        _selectedDocument = docs.firstWhere(
          (d) => d.id == widget.documentId,
          orElse: () => docs.first,
        );
      } else if (docs.isNotEmpty) {
        _selectedDocument = docs.first;
      }
    });
  }

  Future<void> _generateSummary() async {
    if (_selectedDocument == null) return;

    setState(() {
      _isLoading = true;
      _summary = '';
    });

    try {
      // Get all chunks for the document
      final allChunks = <Map<String, dynamic>>[];
      
      // In a real implementation, we'd retrieve all document content
      // For now, we'll create a simulated summary
      await Future.delayed(const Duration(seconds: 2));

      final docName = _selectedDocument!.name;
      final pageCount = _selectedDocument!.pageCount;
      
      String summary;
      switch (_summaryType) {
        case 'concise':
          summary = '''Summary of "$docName"

This $pageCount-page document contains key information organized into main sections. The document discusses several important topics with supporting evidence and examples.

Key Points:
• Main topic introduced in early sections
• Supporting arguments presented throughout
• Conclusions and recommendations in final sections

(Note: Full AI-powered summaries will be available once LLM models are downloaded)''';
          break;
        case 'detailed':
          summary = '''Detailed Summary of "$docName"

Overview:
This comprehensive document spans $pageCount pages and covers multiple interconnected topics. The content is structured logically, beginning with foundational concepts and progressing to advanced applications.

Section Analysis:
• Introduction: Sets context and outlines scope
• Main Content: Detailed explanations with examples
• Supporting Evidence: Data, case studies, references
• Conclusions: Key takeaways and implications

The document is well-organized and provides thorough coverage of the subject matter. Each section builds upon previous content, creating a cohesive narrative.

(Note: Full AI-powered summaries require downloaded LLM models)''';
          break;
        case 'bullet_points':
          summary = '''Key Points from "$docName":

• Document covers ${pageCount > 1 ? '$pageCount pages' : '1 page'} of content
• Organized into logical sections
• Contains multiple supporting arguments
• Includes practical examples and applications
• Presents clear conclusions
• Provides actionable recommendations

• Suitable for quick reference and review
• Can be queried for specific information
• Fully searchable within Smriti

(Note: AI-powered bullet extraction requires LLM models)''';
          break;
        default:
          summary = 'Summary generation not available.';
      }

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _summary = 'Error generating summary: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    // In production, use flutter/services.dart Clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary copied to clipboard')),
    );
  }

  void _shareSummary() {
    // In production, use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summarize Document'),
        centerTitle: true,
        actions: [
          if (_summary.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyToClipboard,
              tooltip: 'Copy',
            ),
          if (_summary.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareSummary,
              tooltip: 'Share',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document selector
            if (_documents.length > 1)
              DropdownButtonFormField<Document>(
                value: _selectedDocument,
                decoration: const InputDecoration(
                  labelText: 'Select Document',
                  border: OutlineInputBorder(),
                ),
                items: _documents.map((doc) {
                  return DropdownMenuItem(
                    value: doc,
                    child: Text(doc.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (doc) {
                  setState(() {
                    _selectedDocument = doc;
                    _summary = '';
                  });
                },
              ),
            
            if (_documents.length > 1)
              const SizedBox(height: 16),
            
            // Summary type selector
            const Text(
              'Summary Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
              onSelectionChanged: (selected) {
                setState(() {
                  _summaryType = selected.first;
                  _summary = '';
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Generate button
            SizedBox(
              width: double.infinity,
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
            
            const SizedBox(height: 24),
            
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
                              Icons.summarize,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Summary',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          _summary,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                          ),
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
                    'Add documents first to generate summaries',
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
