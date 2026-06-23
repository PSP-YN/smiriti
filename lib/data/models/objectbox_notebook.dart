import 'package:objectbox/objectbox.dart';

@Entity()
class ObjectBoxNotebook {
  @Id()
  int id = 0;

  @Index()
  @Unique()
  String notebookId;

  String name;
  String description;
  String createdAt;

  ObjectBoxNotebook({
    required this.notebookId,
    required this.name,
    required this.description,
    required this.createdAt,
  });
}
