import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/services/rag_orchestrator.dart';
import '../../../data/models/objectbox_chat_message.dart';
import '../../../data/objectbox_store.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatInitial()) {
    on<LoadChatHistory>(_onLoadHistory);
    on<SendMessage>(_onSendMessage);
    on<ClearChat>(_onClearChat);
    on<ExportChat>(_onExportChat);
  }

  static const _sessionId = 'default_session';

  Future<void> _onLoadHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    final allMessages = ObjectBoxStore.getAllChatMessages(_sessionId);
    final messages = allMessages
        .map((m) => ChatMessageData(
              text: m.message,
              isUser: m.isUser,
              timestamp: DateTime.parse(m.createdAt),
              sources: m.sourcesJson != null
                  ? (jsonDecode(m.sourcesJson!) as List<dynamic>)
                      .cast<Map<String, dynamic>>()
                  : null,
              confidence: m.confidence,
            ))
        .toList();
    emit(ChatLoaded(messages));
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    final messages = currentState is ChatLoaded
        ? List<ChatMessageData>.from(currentState.messages)
        : <ChatMessageData>[];

    final userMsg = ChatMessageData(
      text: event.query,
      isUser: true,
      timestamp: DateTime.now(),
    );
    messages.add(userMsg);

    _saveMessage(event.query, true, null, null);
    emit(ChatLoading(messages));

    try {
      final result = await RAGOrchestrator.generateAnswer(
        event.query,
        documentIds: event.documentIds?.isEmpty == true ? null : event.documentIds,
      );

      final botMsg = ChatMessageData(
        text: result.answer,
        isUser: false,
        timestamp: DateTime.now(),
        sources: result.citations
            .map((c) => {
                  'docId': c.documentId,
                  'docName': c.documentName,
                  'page': c.pageNumber,
                  'content': c.content,
                })
            .toList(),
        confidence: result.confidence,
      );
      messages.add(botMsg);

      final sourcesJson = jsonEncode(result.citations
          .map((c) => {
                'docId': c.documentId,
                'docName': c.documentName,
                'page': c.pageNumber,
                'content': c.content,
              })
          .toList());
      _saveMessage(result.answer, false, sourcesJson, result.confidence);

      emit(ChatLoaded(messages));
    } catch (e) {
      final errorMsg = ChatMessageData(
        text: 'Error: ${e.toString().split('\n').first}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(errorMsg);
      _saveMessage(errorMsg.text, false, null, null);
      emit(ChatLoaded(messages));
    }
  }

  void _saveMessage(String text, bool isUser, String? sourcesJson, double? confidence) {
    ObjectBoxStore.insertChatMessage(ObjectBoxChatMessage(
      sessionId: _sessionId,
      message: text,
      isUser: isUser,
      createdAt: DateTime.now().toIso8601String(),
      sourcesJson: sourcesJson,
      confidence: confidence,
    ));
  }

  Future<void> _onClearChat(
    ClearChat event,
    Emitter<ChatState> emit,
  ) async {
    ObjectBoxStore.clearChatSession(_sessionId);
    emit(ChatInitial());
  }

  Future<void> _onExportChat(
    ExportChat event,
    Emitter<ChatState> emit,
  ) async {
    final allMessages = ObjectBoxStore.getAllChatMessages(_sessionId);
    final buffer = StringBuffer();
    buffer.writeln('# Smriti Chat Export');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    for (final m in allMessages) {
      final role = m.isUser ? 'You' : 'Smriti';
      buffer.writeln('## $role (${m.createdAt})');
      buffer.writeln(m.message);
      buffer.writeln();
    }

    emit(ChatExportReady(buffer.toString()));
  }
}
