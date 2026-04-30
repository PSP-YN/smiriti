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

  @Property(type: PropertyType.byteVector)
  List<double>? embedding;

  String createdAt;

  ObjectBoxChunk({
    required this.documentId,
    required this.content,
    required this.pageNumber,
    required this.position,
    this.embedding,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'content': content,
      'pageNumber': pageNumber,
      'position': position,
      'embedding': embedding,
      'createdAt': createdAt,
    };
  }

  factory ObjectBoxChunk.fromJson(Map<String, dynamic> json) {
    return ObjectBoxChunk(
      documentId: json['documentId'] as String,
      content: json['content'] as String,
      pageNumber: json['pageNumber'] as int,
      position: json['position'] as int,
      embedding: (json['embedding'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      createdAt: json['createdAt'] as String,
    )..id = json['id'] as int? ?? 0;
  }
}
