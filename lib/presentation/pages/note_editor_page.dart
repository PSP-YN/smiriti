import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/llm_service.dart';
import '../../data/models/objectbox_note.dart';
import '../../data/objectbox_store.dart';

class NoteEditorPage extends StatefulWidget {
  final String? noteId;

  const NoteEditorPage({super.key, this.noteId});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSaving = false;
  bool _isAIProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _loadNote();
    }
  }

  void _loadNote() {
    final note = ObjectBoxStore.getNote(widget.noteId!);
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
    }
  }

  Future<void> _saveNote() async {
    setState(() => _isSaving = true);
    final now = DateTime.now().toIso8601String();
    final noteId = widget.noteId ?? const Uuid().v4();

    final note = ObjectBoxNote(
      noteId: noteId,
      title: _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
      content: _contentController.text,
      createdAt: now,
      updatedAt: now,
    );

    ObjectBoxStore.insertNote(note);
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note saved')),
    );
  }

  Future<void> _askAI(String action) async {
    if (_contentController.text.isEmpty) return;

    setState(() => _isAIProcessing = true);
    try {
      String prompt = '';
      if (action == 'summarize') {
        prompt = 'Summarize the following text concisely:\n\n${_contentController.text}';
      } else if (action == 'expand') {
        prompt = 'Expand on the following thoughts and provide more detail:\n\n${_contentController.text}';
      } else if (action == 'fix') {
        prompt = 'Fix grammar and improve the clarity of the following text:\n\n${_contentController.text}';
      }

      final response = await LLMService.generate(prompt);

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AI Suggestion', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(response),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Discard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          _contentController.text += '\n\n---\nAI Suggestion:\n$response';
                          Navigator.pop(ctx);
                        },
                        child: const Text('Append to Note'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAIProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        actions: [
          if (_isAIProcessing)
            const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
          PopupMenuButton<String>(
            icon: const Icon(Icons.auto_awesome),
            onSelected: _askAI,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'summarize', child: Text('Summarize')),
              const PopupMenuItem(value: 'expand', child: Text('Expand')),
              const PopupMenuItem(value: 'fix', child: Text('Improve Writing')),
            ],
          ),
          IconButton(
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Start writing...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
