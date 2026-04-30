import 'package:equatable/equatable.dart';

class Document extends Equatable {
  final String id;
  final String name;
  final String path;
  final String type;
  final DateTime createdAt;
  final int pageCount;
  final String? thumbnailPath;
  final List<String> extractedText;

  const Document({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.createdAt,
    this.pageCount = 0,
    this.thumbnailPath,
    this.extractedText = const [],
  });

  Document copyWith({
    String? id,
    String? name,
    String? path,
    String? type,
    DateTime? createdAt,
    int? pageCount,
    String? thumbnailPath,
    List<String>? extractedText,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      pageCount: pageCount ?? this.pageCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      extractedText: extractedText ?? this.extractedText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'pageCount': pageCount,
      'thumbnailPath': thumbnailPath,
      'extractedText': extractedText,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      pageCount: json['pageCount'] as int? ?? 0,
      thumbnailPath: json['thumbnailPath'] as String?,
      extractedText: (json['extractedText'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        type,
        createdAt,
        pageCount,
        thumbnailPath,
        extractedText,
      ];
}
