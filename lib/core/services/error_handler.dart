import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handleError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    if (kDebugMode) {
      final message = context != null ? '[$context] $error' : error.toString();
      developer.log(
        message,
        error: error,
        stackTrace: stackTrace,
        level: fatal ? 1000 : 800,
      );
    }
  }

  static void logInfo(String message, {String? context}) {
    if (kDebugMode) {
      developer.log(
        context != null ? '[$context] $message' : message,
        level: 500,
      );
    }
  }

  static void logWarning(String message, {String? context}) {
    if (kDebugMode) {
      developer.log(
        context != null ? '[$context] $message' : message,
        level: 700,
      );
    }
  }
}
