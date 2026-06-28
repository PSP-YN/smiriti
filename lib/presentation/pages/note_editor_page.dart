import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../data/models/objectbox_note.dart';
import '../../data/models/objectbox_notebook.dart';
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
  List<ObjectBoxNotebook> _notebooks = [];
  String? _selectedNotebookId;
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEditing => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final notebooks = ObjectBoxStore.getAllNotebooks();
    setState(() => _notebooks = notebooks);

    if (_isEditing) {
      final note = ObjectBoxStore.getNoteById(widget.noteId!);
      if (note != null) {
        _titleController.text = note.title;
        _contentController.text = note.content;
        _selectedNotebookId = note.notebookId;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) return;

    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();

    if (_isEditing) {
      ObjectBoxStore.updateNote(widget.noteId!, title, content,
          notebookId: _selectedNotebookId);
    } else {
      ObjectBoxStore.insertNote(ObjectBoxNote(
        noteId: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        notebookId: _selectedNotebookId,
      ));
    }

    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _share() async {
    final text = '${_titleController.text}\n\n${_contentController.text}';
    await Share.share(text);
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      return true;
    }
    if (_isEditing) {
      final note = ObjectBoxStore.getNoteById(widget.noteId!);
      if (note != null &&
          note.title == _titleController.text &&
          note.content == _contentController.text) {
        return true;
      }
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Note' : 'New Note'),
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: _share, tooltip: 'Share'),
            IconButton(
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              onPressed: _isSaving ? null : _save,
              tooltip: 'Save',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: !_isEditing,
                    ),
                  ),
                  if (_notebooks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: DropdownButtonFormField<String>(
                        value: _selectedNotebookId,
                        decoration: const InputDecoration(
                          labelText: 'Notebook',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ..._notebooks.map((n) => DropdownMenuItem(
                                value: n.notebookId,
                                child: Text(n.name),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedNotebookId = v),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          hintText: 'Start writing...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
