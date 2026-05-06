import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';
import 'models/objectbox_chunk.dart';
import 'models/objectbox_document.dart';

class ObjectBoxStore {
  static Store? _store;
  static Box<ObjectBoxDocument>? _documentBox;
  static Box<ObjectBoxChunk>? _chunkBox;

  static Future<void> initialize() async {
    if (_store != null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final storeDir = Directory('${docsDir.path}/objectbox');
    if (!await storeDir.exists()) await storeDir.create(recursive: true);

    _store = Store(getObjectBoxModel(), directory: storeDir.path);
    _documentBox = _store!.box<ObjectBoxDocument>();
    _chunkBox = _store!.box<ObjectBoxChunk>();
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

  static void close() {
    _store?.close();
    _store = null;
    _documentBox = null;
    _chunkBox = null;
  }

  static Future<void> clearAll() async {
    await documentBox.removeAllAsync();
    await chunkBox.removeAllAsync();
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
}
