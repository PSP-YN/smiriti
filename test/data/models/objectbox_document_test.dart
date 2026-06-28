import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/data/models/objectbox_document.dart';

void main() {
  group('ObjectBoxDocument', () {
    test('toJson and fromJson round-trip', () {
      final doc = ObjectBoxDocument(
        documentId: 'doc-1',
        name: 'test.pdf',
        path: '/tmp/test.pdf',
        type: 'pdf',
        createdAt: '2024-01-01T00:00:00',
        pageCount: 3,
        thumbnailPath: '/tmp/thumb.png',
        notebookId: 'nb-1',
      );

      final json = doc.toJson();
      final restored = ObjectBoxDocument.fromJson(json);

      expect(restored.documentId, doc.documentId);
      expect(restored.name, doc.name);
      expect(restored.path, doc.path);
      expect(restored.type, doc.type);
      expect(restored.createdAt, doc.createdAt);
      expect(restored.pageCount, doc.pageCount);
      expect(restored.thumbnailPath, doc.thumbnailPath);
      expect(restored.notebookId, doc.notebookId);
    });

    test('toJson handles null fields', () {
      final doc = ObjectBoxDocument(
        documentId: 'doc-2',
        name: 'test.txt',
        path: '/tmp/test.txt',
        type: 'txt',
        createdAt: '2024-01-01T00:00:00',
      );

      final json = doc.toJson();
      expect(json['thumbnailPath'], isNull);
      expect(json['notebookId'], isNull);
      expect(json['pageCount'], 0);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 0,
        'documentId': 'doc-3',
        'name': 'doc.pdf',
        'path': '/tmp/doc.pdf',
        'type': 'pdf',
        'createdAt': '2024-01-01T00:00:00',
      };

      final doc = ObjectBoxDocument.fromJson(json);
      expect(doc.pageCount, 0);
      expect(doc.thumbnailPath, isNull);
      expect(doc.notebookId, isNull);
    });
  });
}
