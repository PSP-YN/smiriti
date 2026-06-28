part of 'chat_bloc.dart';

class ChatMessageData extends Equatable {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Map<String, dynamic>>? sources;
  final double? confidence;

  const ChatMessageData({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
    this.confidence,
  });

  @override
  List<Object?> get props => [text, isUser, timestamp, sources, confidence];
}

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessageData> messages;

  const ChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatLoading extends ChatState {
  final List<ChatMessageData> messages;

  const ChatLoading(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatExportReady extends ChatState {
  final String markdown;

  const ChatExportReady(this.markdown);

  @override
  List<Object?> get props => [markdown];
}
