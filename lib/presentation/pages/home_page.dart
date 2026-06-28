import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../core/constants/app_constants.dart';
import '../../data/models/objectbox_note.dart';
import '../../data/models/objectbox_notebook.dart';
import '../../data/objectbox_store.dart';
import 'chat_page.dart';
import 'note_editor_page.dart';
import 'settings_page.dart';
import 'summarize_page.dart';
import 'notebook_detail_page.dart';
import 'image_capture_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ObjectBoxNote> _notes = [];
  List<ObjectBoxNotebook> _notebooks = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final notes = ObjectBoxStore.getAllNotes(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    final notebooks = ObjectBoxStore.getAllNotebooks();
    setState(() {
      _notes = notes;
      _notebooks = notebooks;
      _isLoading = false;
    });
  }

  Future<void> _createNotebook() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Notebook'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Notebook name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.isNotEmpty),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result == true) {
      ObjectBoxStore.insertNotebook(ObjectBoxNotebook(
        notebookId: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text,
        description: descController.text,
        createdAt: DateTime.now().toIso8601String(),
      ));
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())).then((_) => _loadData()),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colorScheme.primaryContainer),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_stories, size: 48),
                    const SizedBox(height: 8),
                    Text(AppConstants.appName, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('AI Chat'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage())),
            ),
            ListTile(
              leading: const Icon(Icons.summarize_outlined),
              title: const Text('Summarize'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SummarizePage())),
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner),
              title: const Text('Import Documents'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImageCapturePage())).then((_) => _loadData()),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('NOTEBOOKS', style: Theme.of(context).textTheme.labelSmall),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ..._notebooks.map((n) => ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(n.name),
                    subtitle: n.description.isNotEmpty ? Text(n.description, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () async {
                        await ObjectBoxStore.deleteNotebook(n.notebookId);
                        await _loadData();
                      },
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotebookDetailPage(notebookId: n.notebookId, notebookName: n.name))).then((_) => _loadData()),
                  )),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Create Notebook'),
                    onTap: _createNotebook,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _loadData();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withAlpha(80),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                  _loadData();
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notes.isEmpty
                      ? _buildEmptyState()
                      : _buildNotesGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoteEditorPage()),
        ).then((_) => _loadData()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.withAlpha(100)),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? 'No notes match your search' : 'No notes yet',
                style: const TextStyle(color: Colors.grey, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty ? 'Try a different search term' : 'Start by creating a new note or notebook',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (_searchQuery.isEmpty)
                FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteEditorPage())).then((_) => _loadData()),
                  icon: const Icon(Icons.add),
                  label: const Text('New Note'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.withAlpha(50)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: note.noteId)),
            ).then((_) => _loadData()),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.withAlpha(150)),
                        onSelected: (val) async {
                          if (val == 'share') {
                            await Share.share('${note.title}\n\n${note.content}');
                          } else if (val == 'delete') {
                            await ObjectBoxStore.deleteNote(note.noteId);
                            await _loadData();
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'share', child: Text('Share')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      note.content,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
