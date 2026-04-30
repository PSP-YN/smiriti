import 'package:equatable/equatable.dart';

class DocumentChunk extends Equatable {
  final String id;
  final String documentId;
  final String content;
  final int pageNumber;
  final int position;
  final List<double>? embedding;
  final DateTime createdAt;

  const DocumentChunk({
    required this.id,
    required this.documentId,
    required this.content,
    required this.pageNumber,
    required this.position,
    this.embedding,
    required this.createdAt,
  });

  DocumentChunk copyWith({
    String? id,
    String? documentId,
    String? content,
    int? pageNumber,
    int? position,
    List<double>? embedding,
    DateTime? createdAt,
  }) {
    return DocumentChunk(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      position: position ?? this.position,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'content': content,
      'pageNumber': pageNumber,
      'position': position,
      'embedding': embedding,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DocumentChunk.fromJson(Map<String, dynamic> json) {
    return DocumentChunk(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      content: json['content'] as String,
      pageNumber: json['pageNumber'] as int,
      position: json['position'] as int,
      embedding: (json['embedding'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        documentId,
        content,
        pageNumber,
        position,
        embedding,
        createdAt,
      ];
}
