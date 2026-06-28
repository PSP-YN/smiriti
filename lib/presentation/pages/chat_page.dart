import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

import '../../core/constants/app_constants.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../bloc/chat/chat_bloc.dart';
import '../widgets/chat_bubble.dart';
import 'image_capture_page.dart';

class ChatPage extends StatefulWidget {
  final String? initialDocumentId;

  const ChatPage({super.key, this.initialDocumentId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _repository = GetIt.I<DocumentRepository>();
  late final ChatBloc _chatBloc;
  List<Document> _documents = [];
  final List<String> _selectedDocIds = [];

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc();
    _chatBloc.add(const LoadChatHistory());
    _loadDocuments();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatBloc.close();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    final docs = await _repository.getAllDocuments();
    if (mounted) {
      setState(() {
        _documents = docs;
        if (widget.initialDocumentId != null &&
            docs.any((d) => d.id == widget.initialDocumentId)) {
          _selectedDocIds.clear();
          _selectedDocIds.add(widget.initialDocumentId!);
        }
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    _chatBloc.add(SendMessage(
      text,
      documentIds: _selectedDocIds.isEmpty ? null : _selectedDocIds,
    ));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _exportChat() async {
    _chatBloc.add(const ExportChat());
    final state = _chatBloc.state;
    if (state is ChatExportReady) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/smriti_chat_export.md');
      await file.writeAsString(state.markdown);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Smriti Chat Export',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDocName = _selectedDocIds.isNotEmpty && _documents.isNotEmpty
        ? _documents
            .where((d) => d.id == _selectedDocIds.first)
            .map((d) => d.name)
            .firstOrNull
        : null;

    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              const Text('Ask Smriti',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (selectedDocName != null)
                Text(
                  selectedDocName,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withAlpha(160),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else if (_documents.isNotEmpty)
                Text(
                  'All ${_documents.length} documents',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withAlpha(160),
                  ),
                ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.note_add),
              tooltip: 'Add document',
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const ImageCapturePage()),
                );
                if (result == true) await _loadDocuments();
              },
            ),
            if (_documents.isNotEmpty)
              IconButton(
                icon: Badge(
                  isLabelVisible: _selectedDocIds.isNotEmpty,
                  label: Text('${_selectedDocIds.length}'),
                  child: const Icon(Icons.filter_list),
                ),
                tooltip: 'Filter documents',
                onPressed: _showDocumentFilter,
              ),
            IconButton(
              icon: const Icon(Icons.file_upload_outlined),
              tooltip: 'Export chat',
              onPressed: _exportChat,
            ),
          ],
        ),
        body: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatInitial && _documents.isEmpty) {
              return _buildEmptyState(true);
            }
            if (state is ChatLoaded || state is ChatLoading) {
              final messages = state is ChatLoaded
                  ? state.messages
                  : (state as ChatLoading).messages;
              final isProcessing = state is ChatLoading;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: colorScheme.primaryContainer.withAlpha(40),
                    child: Row(
                      children: [
                        Icon(Icons.offline_bolt, size: 14, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            AppConstants.offlineMessage,
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: messages.isEmpty
                        ? _buildEmptyState(false)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              return ChatBubble(
                                message: msg.text,
                                isUser: msg.isUser,
                                timestamp: msg.timestamp,
                                sources: msg.sources,
                              );
                            },
                          ),
                  ),
                  if (isProcessing)
                    Container(
                      color: colorScheme.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Searching documents...',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withAlpha(160),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildInputBar(colorScheme),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline.withAlpha(60))),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withAlpha(60),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outline.withAlpha(60)),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Ask about your documents...',
                    hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(100)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'send_btn',
              onPressed: _sendMessage,
              elevation: 0,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noDocs) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 72, color: colorScheme.primary.withAlpha(80)),
            const SizedBox(height: 20),
            Text(
              'Ask about your documents',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                noDocs
                    ? 'Add documents from the home screen first, then return here to ask questions.'
                    : 'Type a question and I\'ll search through your documents and provide answers with citations.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: colorScheme.onSurface.withAlpha(150)),
              ),
            ),
            if (noDocs) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const ImageCapturePage()),
                  );
                  if (result == true) await _loadDocuments();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add a Document'),
              ),
            ] else ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _showDocumentFilter,
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(
                  _selectedDocIds.isEmpty
                      ? 'Filter: all ${_documents.length} docs'
                      : 'Filter: ${_selectedDocIds.length} selected',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDocumentFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            maxChildSize: 0.85,
            builder: (_, scrollCtrl) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('Search In', style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setModalState(() => _selectedDocIds.clear());
                          setState(() {});
                        },
                        child: const Text('All'),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Leave all unchecked to search all documents',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      return CheckboxListTile(
                        title: Text(doc.name),
                        subtitle: Text('${doc.pageCount} pages'),
                        value: _selectedDocIds.contains(doc.id),
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
