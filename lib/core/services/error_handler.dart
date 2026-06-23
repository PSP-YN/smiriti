import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handleError(Object error, StackTrace stackTrace, {String? context}) {
    debugPrint('Error in $context: $error');
    debugPrint('Stack trace:\n$stackTrace');
  }
}
