import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';
import 'models/objectbox_chunk.dart';
import 'models/objectbox_document.dart';
import 'models/objectbox_note.dart';
import 'models/objectbox_notebook.dart';

class ObjectBoxStore {
  static Store? _store;
  static Box<ObjectBoxDocument>? _documentBox;
  static Box<ObjectBoxChunk>? _chunkBox;
  static Box<ObjectBoxNote>? _noteBox;
  static Box<ObjectBoxNotebook>? _notebookBox;

  static Future<void> initialize() async {
    if (_store != null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final storeDir = Directory('${docsDir.path}/objectbox');
    if (!await storeDir.exists()) await storeDir.create(recursive: true);

    _store = Store(getObjectBoxModel(), directory: storeDir.path);
    _documentBox = _store!.box<ObjectBoxDocument>();
    _chunkBox = _store!.box<ObjectBoxChunk>();
    _noteBox = _store!.box<ObjectBoxNote>();
    _notebookBox = _store!.box<ObjectBoxNotebook>();
  }

  static Store get store {
    if (_store == null) throw StateError('ObjectBoxStore not initialized.');
    return _store!;
  }

  static Box<ObjectBoxDocument> get documentBox {
    if (_documentBox == null) throw StateError('ObjectBoxStore not initialized.');
    return _documentBox!;
  }

  static Box<ObjectBoxChunk> get chunkBox {
    if (_chunkBox == null) throw StateError('ObjectBoxStore not initialized.');
    return _chunkBox!;
  }

  static Box<ObjectBoxNote> get noteBox {
    if (_noteBox == null) throw StateError('ObjectBoxStore not initialized.');
    return _noteBox!;
  }

  static Box<ObjectBoxNotebook> get notebookBox {
    if (_notebookBox == null) throw StateError('ObjectBoxStore not initialized.');
    return _notebookBox!;
  }

  static void close() {
    _store?.close();
    _store = null;
    _documentBox = null;
    _chunkBox = null;
    _noteBox = null;
    _notebookBox = null;
  }

  static Future<void> clearAll() async {
    await documentBox.removeAllAsync();
    await chunkBox.removeAllAsync();
    await noteBox.removeAllAsync();
    await notebookBox.removeAllAsync();
  }

  static int insertDocument(ObjectBoxDocument doc) => documentBox.put(doc);

  static ObjectBoxDocument? getDocument(String documentId) {
    final all = documentBox.getAll();
    try {
      return all.firstWhere((d) => d.documentId == documentId);
    } catch (_) {
      return null;
    }
  }

  static List<ObjectBoxDocument> getAllDocuments() => documentBox.getAll();

  static bool deleteDocument(String documentId) {
    final doc = getDocument(documentId);
    if (doc == null) return false;
    deleteChunksForDocument(documentId);
    return documentBox.remove(doc.id);
  }

  static int insertChunk(ObjectBoxChunk chunk) => chunkBox.put(chunk);

  static List<int> insertChunks(List<ObjectBoxChunk> chunks) =>
      chunkBox.putMany(chunks);

  static void deleteChunksForDocument(String documentId) {
    final toDelete = chunkBox
        .getAll()
        .where((c) => c.documentId == documentId)
        .map((c) => c.id)
        .toList();
    chunkBox.removeMany(toDelete);
  }

  static List<ObjectBoxChunk> getChunksForDocument(String documentId) {
    final chunks = chunkBox
        .getAll()
        .where((c) => c.documentId == documentId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return chunks;
  }

  static List<ObjectBoxChunk> getAllChunksWithEmbeddings() =>
      chunkBox.getAll().where((c) => c.embedding != null).toList();

  // ── Notes ──────────────────────────────────────────────────────────────────

  static int insertNote(ObjectBoxNote note) => noteBox.put(note);

  static List<ObjectBoxNote> getAllNotes() => noteBox.getAll();

  static ObjectBoxNote? getNote(String noteId) {
    return noteBox.query(ObjectBoxNote_.noteId.equals(noteId)).build().findFirst();
  }

  static bool deleteNote(String noteId) {
    final note = getNote(noteId);
    if (note == null) return false;
    return noteBox.remove(note.id);
  }

  // ── Notebooks ─────────────────────────────────────────────────────────────

  static int insertNotebook(ObjectBoxNotebook notebook) => notebookBox.put(notebook);

  static List<ObjectBoxNotebook> getAllNotebooks() => notebookBox.getAll();

  static ObjectBoxNotebook? getNotebook(String notebookId) {
    return notebookBox.query(ObjectBoxNotebook_.notebookId.equals(notebookId)).build().findFirst();
  }

  static bool deleteNotebook(String notebookId) {
    final notebook = getNotebook(notebookId);
    if (notebook == null) return false;
    return notebookBox.remove(notebook.id);
  }
}
