import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/data/models/objectbox_note.dart';

void main() {
  group('ObjectBoxNote', () {
    test('creates note with required fields', () {
      final note = ObjectBoxNote(
        noteId: 'test-1',
        title: 'Test Title',
        content: 'Test content',
        createdAt: '2024-01-01T00:00:00',
        updatedAt: '2024-01-01T00:00:00',
      );

      expect(note.noteId, 'test-1');
      expect(note.title, 'Test Title');
      expect(note.content, 'Test content');
      expect(note.createdAt, '2024-01-01T00:00:00');
      expect(note.updatedAt, '2024-01-01T00:00:00');
      expect(note.notebookId, isNull);
    });

    test('creates note with notebookId', () {
      final note = ObjectBoxNote(
        noteId: 'test-2',
        title: 'Note in Notebook',
        content: 'Content here',
        createdAt: '2024-01-01T00:00:00',
        updatedAt: '2024-01-01T00:00:00',
        notebookId: 'nb-1',
      );

      expect(note.notebookId, 'nb-1');
    });

    test('default id is 0', () {
      final note = ObjectBoxNote(
        noteId: 'test-3',
        title: 'Default ID',
        content: 'Content',
        createdAt: '2024-01-01T00:00:00',
        updatedAt: '2024-01-01T00:00:00',
      );

      expect(note.id, 0);
    });
  });
}
