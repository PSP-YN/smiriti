import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/data/models/objectbox_notebook.dart';

void main() {
  group('ObjectBoxNotebook', () {
    test('creates notebook with required fields', () {
      final nb = ObjectBoxNotebook(
        notebookId: 'nb-1',
        name: 'My Notebook',
        description: 'A test notebook',
        createdAt: '2024-01-01T00:00:00',
      );

      expect(nb.notebookId, 'nb-1');
      expect(nb.name, 'My Notebook');
      expect(nb.description, 'A test notebook');
      expect(nb.createdAt, '2024-01-01T00:00:00');
    });
  });
}
