import 'package:objectbox/objectbox.dart';

@Entity()
class ObjectBoxNote {
  @Id()
  int id = 0;

  @Index()
  @Unique()
  String noteId;

  String title;
  String content;
  String createdAt;
  String updatedAt;

  String? notebookId; // Link to a notebook

  ObjectBoxNote({
    required this.noteId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.notebookId,
  });
}
