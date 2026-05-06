import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/document.dart';
import '../pages/chat_page.dart';
import '../pages/summarize_page.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onDelete,
    this.onTap,
  });

  IconData get _fileIcon {
    switch (document.type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
        return Icons.description;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
      case 'bmp':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
      case 'ogg':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color get _fileColor {
    switch (document.type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'txt':
        return Colors.blue;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
      case 'bmp':
        return Colors.green;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
      case 'ogg':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(initialDocumentId: document.id),
                ),
              );
            },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _fileColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_fileIcon, color: _fileColor, size: 26),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'chat':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatPage(initialDocumentId: document.id),
                            ),
                          );
                        case 'summarize':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SummarizePage(documentId: document.id),
                            ),
                          );
                        case 'delete':
                          _showDeleteDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'chat',
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                color: colorScheme.primary, size: 18),
                            const SizedBox(width: 10),
                            const Text('Ask AI'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'summarize',
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: colorScheme.tertiary, size: 18),
                            const SizedBox(width: 10),
                            const Text('Summarize'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            SizedBox(width: 10),
                            Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  document.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dateFormat.format(document.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withAlpha(130),
                ),
              ),
              if (document.pageCount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${document.pageCount} ${document.pageCount == 1 ? 'page' : 'pages'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withAlpha(130),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              // Status badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: document.extractedText.isNotEmpty
                          ? Colors.green.withAlpha(25)
                          : Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          document.extractedText.isNotEmpty
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 10,
                          color: document.extractedText.isNotEmpty
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          document.extractedText.isNotEmpty
                              ? 'Indexed'
                              : 'Pending',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: document.extractedText.isNotEmpty
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content:
            Text('Delete "${document.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
