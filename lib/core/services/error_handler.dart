import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Centralized error handling service
class ErrorHandler {
  static void handleError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    final message = context != null ? '[$context] $error' : error.toString();
    
    if (kDebugMode) {
      developer.log(
        message,
        error: error,
        stackTrace: stackTrace,
        level: fatal ? 1000 : 800,
      );
    }
    
    // TODO: Add crash reporting service integration (e.g., Firebase Crashlytics)
  }
  
  static void logInfo(String message, {String? context}) {
    final fullMessage = context != null ? '[$context] $message' : message;
    
    if (kDebugMode) {
      developer.log(fullMessage, level: 500);
    }
  }
  
  static void logWarning(String message, {String? context}) {
    final fullMessage = context != null ? '[$context] $message' : message;
    
    if (kDebugMode) {
      developer.log(fullMessage, level: 700);
    }
  }
}
