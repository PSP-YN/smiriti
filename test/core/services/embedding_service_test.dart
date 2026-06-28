import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbeddingService', () {
    test('vocab JSON is an array of tokens', () async {
      final vocabFile = File('assets/vocab.json');
      final exists = await vocabFile.exists();
      if (exists) {
        final content = await vocabFile.readAsString();
        final decoded = jsonDecode(content) as List<dynamic>;
        expect(decoded, isNotEmpty);
        expect(decoded.length, greaterThan(100));

        // Token at index 0 should be [PAD]
        expect(decoded[0], '[PAD]');
        // Token at index 1 should be [UNK]
        expect(decoded[1], '[UNK]');
        // Token at index 2 should be [CLS]
        expect(decoded[2], '[CLS]');
        // Token at index 3 should be [SEP]
        expect(decoded[3], '[SEP]');

        // Common English words should be present
        expect(decoded, contains('the'));
        expect(decoded, contains('and'));
        expect(decoded, contains('you'));
      }
    });
  });
}
