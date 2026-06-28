import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/presentation/bloc/chat/chat_bloc.dart';

void main() {
  group('ChatBloc', () {
    test('initial state is ChatInitial', () {
      final chatBloc = ChatBloc();
      expect(chatBloc.state, isA<ChatInitial>());
      chatBloc.close();
    });

    test('event classes are properly defined', () {
      expect(LoadChatHistory(), isA<LoadChatHistory>());
      expect(SendMessage('test'), isA<SendMessage>());
      expect(ClearChat(), isA<ClearChat>());
      expect(ExportChat(), isA<ExportChat>());
    });

    test('state classes are properly defined', () {
      expect(ChatInitial(), isA<ChatInitial>());
      expect(ChatLoaded([]), isA<ChatLoaded>());
      expect(ChatLoading([]), isA<ChatLoading>());
      expect(ChatExportReady('data'), isA<ChatExportReady>());
    });
  });
}
