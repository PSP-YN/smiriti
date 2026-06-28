import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/data/models/objectbox_chat_message.dart';

void main() {
  group('ObjectBoxChatMessage', () {
    test('creates chat message with required fields', () {
      final msg = ObjectBoxChatMessage(
        sessionId: 'session-1',
        message: 'Hello',
        isUser: true,
        createdAt: '2024-01-01T00:00:00',
      );

      expect(msg.sessionId, 'session-1');
      expect(msg.message, 'Hello');
      expect(msg.isUser, isTrue);
      expect(msg.sourcesJson, isNull);
      expect(msg.confidence, isNull);
    });

    test('creates chat message with optional fields', () {
      final msg = ObjectBoxChatMessage(
        sessionId: 'session-1',
        message: 'Response',
        isUser: false,
        createdAt: '2024-01-01T00:00:00',
        sourcesJson: '[{"docId":"doc1"}]',
        confidence: 0.85,
      );

      expect(msg.isUser, isFalse);
      expect(msg.sourcesJson, '[{"docId":"doc1"}]');
      expect(msg.confidence, 0.85);
    });

    test('default id is 0', () {
      final msg = ObjectBoxChatMessage(
        sessionId: 's',
        message: 'm',
        isUser: true,
        createdAt: '2024-01-01T00:00:00',
      );

      expect(msg.id, 0);
    });
  });
}
