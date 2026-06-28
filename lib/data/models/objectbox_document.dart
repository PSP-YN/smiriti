import 'package:objectbox/objectbox.dart';

@Entity()
class ObjectBoxDocument {
  @Id()
  int id = 0;

  @Index()
  @Unique()
  String documentId;

  String name;
  String path;
  String type;
  String createdAt;
  int pageCount;
  String? thumbnailPath;
  String? notebookId;

  @Transient()
  List<String> extractedText;

  ObjectBoxDocument({
    required this.documentId,
    required this.name,
    required this.path,
    required this.type,
    required this.createdAt,
    this.pageCount = 0,
    this.thumbnailPath,
    this.notebookId,
    this.extractedText = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'name': name,
      'path': path,
      'type': type,
      'createdAt': createdAt,
      'pageCount': pageCount,
      'thumbnailPath': thumbnailPath,
      'notebookId': notebookId,
    };
  }

  factory ObjectBoxDocument.fromJson(Map<String, dynamic> json) {
    return ObjectBoxDocument(
      documentId: json['documentId'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      type: json['type'] as String,
      createdAt: json['createdAt'] as String,
      pageCount: json['pageCount'] as int? ?? 0,
      thumbnailPath: json['thumbnailPath'] as String?,
      notebookId: json['notebookId'] as String?,
    )..id = json['id'] as int? ?? 0;
  }
}
