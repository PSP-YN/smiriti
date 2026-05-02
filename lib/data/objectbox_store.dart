import 'dart:io';

import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';
import 'models/objectbox_chunk.dart';
import 'models/objectbox_document.dart';

// NOTE: Run 'dart run build_runner build' to generate ObjectBox code
// This will create objectbox.g.dart with openStore() and entity bindings

class ObjectBoxStore {
  static Store? _store;
  static Box<ObjectBoxDocument>? _documentBox;
  static Box<ObjectBoxChunk>? _chunkBox;

  static Future<void> initialize() async {
    if (_store != null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final storeDir = Directory('${docsDir.path}/objectbox');
    
    if (!await storeDir.exists()) {
      await storeDir.create(recursive: true);
    }

    // Initialize ObjectBox store using generated model
    _store = Store(getObjectBoxModel(), directory: storeDir.path);
    _documentBox = _store!.box<ObjectBoxDocument>();
    _chunkBox = _store!.box<ObjectBoxChunk>();
  }

  static Store get store {
    if (_store == null) {
      throw StateError('ObjectBoxStore not initialized. Call initialize() first.');
    }
    return _store!;
  }

  static Box<ObjectBoxDocument> get documentBox {
    if (_documentBox == null) {
      throw StateError('ObjectBoxStore not initialized. Call initialize() first.');
    }
    return _documentBox!;
  }

  static Box<ObjectBoxChunk> get chunkBox {
    if (_chunkBox == null) {
      throw StateError('ObjectBoxStore not initialized. Call initialize() first.');
    }
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

  static int insertDocument(ObjectBoxDocument doc) {
    return documentBox.put(doc);
  }

  static ObjectBoxDocument? getDocument(String documentId) {
    final all = documentBox.getAll();
    try {
      return all.firstWhere((d) => d.documentId == documentId);
    } catch (_) {
      return null;
    }
  }

  static List<ObjectBoxDocument> getAllDocuments() {
    return documentBox.getAll();
  }

  static bool deleteDocument(String documentId) {
    final doc = getDocument(documentId);
    if (doc == null) return false;
    
    deleteChunksForDocument(documentId);
    return documentBox.remove(doc.id);
  }

  static int insertChunk(ObjectBoxChunk chunk) {
    return chunkBox.put(chunk);
  }

  static List<int> insertChunks(List<ObjectBoxChunk> chunks) {
    return chunkBox.putMany(chunks);
  }

  static void deleteChunksForDocument(String documentId) {
    // TODO: Fix after running 'dart run build_runner build'
    // final query = chunkBox.query(ObjectBoxChunk_.documentId.equals(documentId)).build();
    // query.remove();
    // query.close();
    final all = chunkBox.getAll();
    final toDelete = all.where((c) => c.documentId == documentId).toList();
    chunkBox.removeMany(toDelete.map((c) => c.id).toList());
  }

  static List<ObjectBoxChunk> getChunksForDocument(String documentId) {
    // TODO: Fix after running 'dart run build_runner build'
    // final query = chunkBox.query(ObjectBoxChunk_.documentId.equals(documentId))
    //   .order(ObjectBoxChunk_.position).build();
    // final result = query.find();
    // query.close();
    // return result;
    final all = chunkBox.getAll();
    final filtered = all.where((c) => c.documentId == documentId).toList();
    filtered.sort((a, b) => a.position.compareTo(b.position));
    return filtered;
  }

  static List<ObjectBoxChunk> getAllChunksWithEmbeddings() {
    // Use generated query properties for efficient filtering
    // final query = chunkBox.query(ObjectBoxChunk_.embedding.notNull()).build();
    // final result = query.find();
    // query.close();
    // return result;
    return chunkBox.getAll().where((c) => c.embedding != null).toList();
  }
}
