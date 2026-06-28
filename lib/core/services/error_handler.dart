import 'package:flutter/foundation.dart';

class AppException implements Exception {
  final String message;
  final String? context;
  final Object? originalError;

  const AppException(this.message, {this.context, this.originalError});

  @override
  String toString() {
    final buf = StringBuffer('AppException');
    if (context != null) buf.write('[$context]');
    buf.write(': $message');
    return buf.toString();
  }
}

class ErrorHandler {
  static void handleError(Object error, StackTrace stackTrace, {String? context}) {
    debugPrint('═══ Error in $context ═══');
    debugPrint('Error: $error');
    debugPrint('Stack trace:\n$stackTrace');
    debugPrint('══════════════════════════');
  }

  static String userFacingMessage(Object error) {
    if (error is AppException) return error.message;
    final msg = error.toString();
    // Strip stack traces from user-facing messages
    if (msg.contains('\n')) return msg.split('\n').first;
    return msg;
  }
}
