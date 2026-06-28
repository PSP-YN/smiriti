import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:objectbox/objectbox.dart' as obx;

import '../objectbox.g.dart';
import 'models/objectbox_chat_message.dart';
import 'models/objectbox_chunk.dart';
import 'models/objectbox_document.dart';
import 'models/objectbox_note.dart';
import 'models/objectbox_notebook.dart';

class ObjectBoxStore {
  static Store? _store;
  static Box<ObjectBoxDocument>? _documentBox;
  static Box<ObjectBoxChunk>? _chunkBox;
  static Box<ObjectBoxNote>? _noteBox;
  static Box<ObjectBoxChatMessage>? _chatMessageBox;
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
    _chatMessageBox = _store!.box<ObjectBoxChatMessage>();
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

  static Box<ObjectBoxChatMessage> get chatMessageBox {
    if (_chatMessageBox == null) throw StateError('ObjectBoxStore not initialized.');
    return _chatMessageBox!;
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
    _chatMessageBox = null;
    _notebookBox = null;
  }

  static Future<void> clearAll() async {
    await documentBox.removeAllAsync();
    await chunkBox.removeAllAsync();
    await noteBox.removeAllAsync();
    await chatMessageBox.removeAllAsync();
    await notebookBox.removeAllAsync();
  }

  static int insertDocument(ObjectBoxDocument doc) => documentBox.put(doc);

  static ObjectBoxDocument? getDocument(String documentId) {
    final query = documentBox.query(
      ObjectBoxDocument_.documentId.equals(documentId),
    ).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  static List<ObjectBoxDocument> getAllDocuments({String? search}) {
    if (search != null && search.isNotEmpty) {
      final query = documentBox.query(
        ObjectBoxDocument_.name.contains(search, caseSensitive: false),
      ).build();
      final results = query.find();
      query.close();
      return results;
    }
    return documentBox.getAll();
  }

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
    final query = chunkBox.query(
      ObjectBoxChunk_.documentId.equals(documentId),
    ).build();
    final toDelete = query.find().map((c) => c.id).toList();
    query.close();
    chunkBox.removeMany(toDelete);
  }

  static List<ObjectBoxChunk> getChunksForDocument(String documentId) {
      final query = chunkBox.query(
        ObjectBoxChunk_.documentId.equals(documentId),
      ).order(ObjectBoxChunk_.position).build();
    final results = query.find();
    query.close();
    return results;
  }

  static List<ObjectBoxChunk> getAllChunksWithEmbeddings({String? documentId, int? limit}) {
    var condition = ObjectBoxChunk_.embedding.notNull();
    if (documentId != null) {
      condition = condition & ObjectBoxChunk_.documentId.equals(documentId);
    }
    final query = chunkBox.query(condition).build();
    if (limit != null) query.limit = limit;
    final results = query.find();
    query.close();
    return results;
  }

  static int chunkCount() => chunkBox.count();

  static int documentCount() => documentBox.count();

  // ── Notes ──────────────────────────────────────────────────────────────────

  static int insertNote(ObjectBoxNote note) => noteBox.put(note);

  static List<ObjectBoxNote> getAllNotes({String? search}) {
    if (search != null && search.isNotEmpty) {
      final query = noteBox.query(
        ObjectBoxNote_.title.contains(search, caseSensitive: false) |
        ObjectBoxNote_.content.contains(search, caseSensitive: false),
      ).build();
      final results = query.find();
      query.close();
      return results;
    }
    return noteBox.getAll();
  }

  static ObjectBoxNote? getNoteById(String noteId) {
    final query = noteBox.query(ObjectBoxNote_.noteId.equals(noteId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  static bool deleteNote(String noteId) {
    final note = getNoteById(noteId);
    if (note == null) return false;
    return noteBox.remove(note.id);
  }

  static void updateNote(String noteId, String title, String content, {String? notebookId}) {
    final note = getNoteById(noteId);
    if (note == null) return;
    note.title = title;
    note.content = content;
    note.updatedAt = DateTime.now().toIso8601String();
    if (notebookId != null) note.notebookId = notebookId;
    noteBox.put(note);
  }

  // ── Chat Messages ─────────────────────────────────────────────────────────

  static int insertChatMessage(ObjectBoxChatMessage msg) => chatMessageBox.put(msg);

  static List<ObjectBoxChatMessage> getAllChatMessages(String sessionId) {
    final query = chatMessageBox.query(
      ObjectBoxChatMessage_.sessionId.equals(sessionId),
    ).order(ObjectBoxChatMessage_.id).build();
    final results = query.find();
    query.close();
    return results;
  }

  static void clearChatSession(String sessionId) {
    final query = chatMessageBox.query(
      ObjectBoxChatMessage_.sessionId.equals(sessionId),
    ).build();
    final ids = query.find().map((m) => m.id).toList();
    query.close();
    chatMessageBox.removeMany(ids);
  }

  static List<ObjectBoxNote> getAllNotebookNotes(String notebookId) {
    final query = noteBox.query(
      ObjectBoxNote_.notebookId.equals(notebookId),
    ).build();
    final results = query.find();
    query.close();
    return results;
  }

  // ── Notebooks ─────────────────────────────────────────────────────────────

  static int insertNotebook(ObjectBoxNotebook notebook) => notebookBox.put(notebook);

  static List<ObjectBoxNotebook> getAllNotebooks() => notebookBox.getAll();

  static ObjectBoxNotebook? getNotebook(String notebookId) {
    final query = notebookBox.query(
      ObjectBoxNotebook_.notebookId.equals(notebookId),
    ).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  static bool deleteNotebook(String notebookId) {
    final notebook = getNotebook(notebookId);
    if (notebook == null) return false;
    return notebookBox.remove(notebook.id);
  }
}
