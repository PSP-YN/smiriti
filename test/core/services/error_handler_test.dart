import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/services/error_handler.dart';

void main() {
  group('AppException', () {
    test('creates exception with context and original error', () {
      final original = FormatException('invalid input');
      final exc = AppException(
        'Something went wrong',
        context: 'Parsing',
        originalError: original,
      );

      expect(exc.message, 'Something went wrong');
      expect(exc.context, 'Parsing');
      expect(exc.originalError, original);
    });

    test('toString contains all fields', () {
      final exc = AppException(
        'Error msg',
        context: 'Ctx',
        originalError: Exception('cause'),
      );

      final str = exc.toString();
      expect(str, contains('AppException'));
      expect(str, contains('Error msg'));
      expect(str, contains('Ctx'));
    });
  });

  group('ErrorHandler', () {
    test('userFacingMessage returns AppException message', () {
      final exc = AppException('Custom error message');
      expect(ErrorHandler.userFacingMessage(exc), 'Custom error message');
    });

    test('userFacingMessage strips stack trace from string errors', () {
      expect(
        ErrorHandler.userFacingMessage('Simple error'),
        'Simple error',
      );
    });

    test('userFacingMessage returns first line of multi-line errors', () {
      expect(
        ErrorHandler.userFacingMessage('First line\nSecond line\nStack trace'),
        'First line',
      );
    });
  });
}
