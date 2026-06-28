import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../data/models/objectbox_note.dart';
import '../../data/objectbox_store.dart';
import 'note_editor_page.dart';

class NotebookDetailPage extends StatefulWidget {
  final String notebookId;
  final String notebookName;

  const NotebookDetailPage({
    super.key,
    required this.notebookId,
    required this.notebookName,
  });

  @override
  State<NotebookDetailPage> createState() => _NotebookDetailPageState();
}

class _NotebookDetailPageState extends State<NotebookDetailPage> {
  List<ObjectBoxNote> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = ObjectBoxStore.getAllNotebookNotes(widget.notebookId);
    setState(() => _notes = notes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notebookName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              if (_notes.isEmpty) return;
              final buf = StringBuffer();
              buf.writeln('# ${widget.notebookName}\n');
              for (final n in _notes) {
                buf.writeln('## ${n.title}');
                buf.writeln(n.content);
                buf.writeln();
              }
              await Share.share(buf.toString());
            },
          ),
        ],
      ),
      body: _notes.isEmpty
          ? const Center(child: Text('No notes in this notebook'))
          : RefreshIndicator(
              onRefresh: _loadNotes,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notes.length,
                itemBuilder: (_, i) {
                  final note = _notes[i];
                  return Card(
                    child: ListTile(
                      title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) async {
                          if (val == 'delete') {
                            await ObjectBoxStore.deleteNote(note.noteId);
                            await _loadNotes();
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: note.noteId)),
                      ).then((_) => _loadNotes()),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
