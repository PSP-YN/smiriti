import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/objectbox_note.dart';
import '../../data/models/objectbox_notebook.dart';
import '../../data/objectbox_store.dart';
import 'chat_page.dart';
import 'note_editor_page.dart';
import 'settings_page.dart';
import 'summarize_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ObjectBoxNote> _notes = [];
  List<ObjectBoxNotebook> _notebooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final notes = ObjectBoxStore.getAllNotes();
    final notebooks = ObjectBoxStore.getAllNotebooks();
    setState(() {
      _notes = notes;
      _notebooks = notebooks;
      _isLoading = false;
    });
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
                    onTap: () {
                       // TODO: Implement Notebook Detail View
                    },
                  )),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Create Notebook'),
                    onTap: () {
                      // TODO: Implement Create Notebook Dialog
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? _buildEmptyState()
              : _buildNotesGrid(),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.withAlpha(100)),
          const SizedBox(height: 16),
          const Text('No notes yet', style: TextStyle(color: Colors.grey, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Start by creating a new note or notebook'),
        ],
      ),
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
                  Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
