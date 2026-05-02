import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

@Entity()
class ObjectBoxChunk {
  @Id()
  int id = 0;

  @Index()
  String documentId;

  String content;
  int pageNumber;
  int position;

  /// Stored as raw bytes (IEEE 754 float32 byte array) for ObjectBox byteVector.
  @Property(type: PropertyType.byteVector)
  List<int>? embedding;

  String createdAt;

  ObjectBoxChunk({
    required this.documentId,
    required this.content,
    required this.pageNumber,
    required this.position,
    this.embedding,
    required this.createdAt,
  });

  /// Store float64 (double) embeddings as float32 bytes to save space.
  List<double>? get embeddingFloats {
    if (embedding == null) return null;
    final bytes = Uint8List.fromList(embedding!);
    final floatList = Float32List.view(bytes.buffer);
    return floatList.map((f) => f.toDouble()).toList();
  }

  set embeddingFloats(List<double>? floats) {
    if (floats == null) {
      embedding = null;
      return;
    }
    final float32 = Float32List(floats.length);
    for (var i = 0; i < floats.length; i++) {
      float32[i] = floats[i];
    }
    embedding = float32.buffer.asUint8List().toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'content': content,
      'pageNumber': pageNumber,
      'position': position,
      'embedding': embeddingFloats,
      'createdAt': createdAt,
    };
  }

  factory ObjectBoxChunk.fromJson(Map<String, dynamic> json) {
    final chunk = ObjectBoxChunk(
      documentId: json['documentId'] as String,
      content: json['content'] as String,
      pageNumber: json['pageNumber'] as int,
      position: json['position'] as int,
      createdAt: json['createdAt'] as String,
    )..id = json['id'] as int? ?? 0;
    
    final emb = (json['embedding'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList();
    chunk.embeddingFloats = emb;
    return chunk;
  }
}
