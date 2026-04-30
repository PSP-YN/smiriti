import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/services/rag_orchestrator.dart';
import '../widgets/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final DocumentRepository _repository = GetIt.I<DocumentRepository>();
  bool _isProcessing = false;
  List<Document> _documents = [];
  List<String> _selectedDocIds = []; // Empty = search all documents

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final docs = await _repository.getAllDocuments();
    setState(() {
      _documents = docs;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isProcessing = true;
    });

    _messageController.clear();
    _scrollToBottom();

    _generateResponse(text);
  }

  Future<void> _generateResponse(String query) async {
    setState(() {
      _isProcessing = true;
    });

    final documents = await _repository.getAllDocuments();
    
    if (documents.isEmpty) {
      setState(() {
        _messages.add({
          'text': 'Please add some documents first so I can help answer your questions.',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isProcessing = false;
      });
      _scrollToBottom();
      return;
    }

    // Use RAG orchestrator for semantic search and answer generation
    final result = await RAGOrchestrator.generateAnswer(
      query,
      documentIds: _selectedDocIds.isEmpty ? null : _selectedDocIds,
    );

    setState(() {
      _messages.add({
        'text': result.answer,
        'isUser': false,
        'timestamp': DateTime.now(),
        'sources': result.citations.map((c) => {
          'docId': c.documentId,
          'docName': c.documentName,
          'page': c.pageNumber,
          'content': c.content,
        }).toList(),
        'confidence': result.confidence,
      });
      _isProcessing = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Smriti'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(30),
            child: const Row(
              children: [
                Icon(Icons.offline_bolt, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppConstants.offlineMessage,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return ChatBubble(
                        message: msg['text'] as String,
                        isUser: msg['isUser'] as bool,
                        timestamp: msg['timestamp'] as DateTime,
                        sources: msg['sources'] as List<Map<String, dynamic>>?,
                      );
                    },
                  ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Thinking...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ask a question about your documents...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withAlpha(100),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start a conversation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ask questions about your documents and I\'ll find the answers with citations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ),
          if (_documents.isNotEmpty)
            TextButton.icon(
              onPressed: _showDocumentFilter,
              icon: const Icon(Icons.filter_list),
              label: Text(_selectedDocIds.isEmpty 
                ? 'Search all ${_documents.length} documents'
                : 'Search ${_selectedDocIds.length} selected'),
            ),
        ],
      ),
    );
  }

  void _showDocumentFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Documents to Search',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Leave all unchecked to search across all documents',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      final isSelected = _selectedDocIds.contains(doc.id);
                      return CheckboxListTile(
                        title: Text(doc.name),
                        subtitle: Text('${doc.pageCount} pages'),
                        value: isSelected,
                        onChanged: (selected) {
                          setModalState(() {
                            if (selected == true) {
                              _selectedDocIds.add(doc.id);
                            } else {
                              _selectedDocIds.remove(doc.id);
                            }
                          });
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedDocIds.clear();
                        });
                        setState(() {});
                      },
                      child: const Text('Clear All'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
