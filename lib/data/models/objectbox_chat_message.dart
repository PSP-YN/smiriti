import 'package:objectbox/objectbox.dart';

@Entity()
class ObjectBoxChatMessage {
  @Id()
  int id = 0;

  @Index()
  String sessionId;

  String message;
  bool isUser;
  String createdAt;
  String? sourcesJson;
  double? confidence;

  ObjectBoxChatMessage({
    required this.sessionId,
    required this.message,
    required this.isUser,
    required this.createdAt,
    this.sourcesJson,
    this.confidence,
  });
}
