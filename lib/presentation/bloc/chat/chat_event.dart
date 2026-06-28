part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatHistory extends ChatEvent {
  const LoadChatHistory();
}

class SendMessage extends ChatEvent {
  final String query;
  final List<String>? documentIds;

  const SendMessage(this.query, {this.documentIds});

  @override
  List<Object?> get props => [query, documentIds];
}

class ClearChat extends ChatEvent {
  const ClearChat();
}

class ExportChat extends ChatEvent {
  const ExportChat();
}
