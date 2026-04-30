import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Application error types
enum ErrorType {
  network,
  storage,
  parsing,
  ocr,
  audio,
  llm,
  unknown,
}

/// Custom application exception
class AppException implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    required this.type,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException($type): $message';
}

/// Global error handler
class ErrorHandler {
  static final List<AppException> _errorLog = [];
  static final _errorController = StreamController<AppException>.broadcast();
  
  static Stream<AppException> get errorStream => _errorController.stream;
  static List<AppException> get errorLog => List.unmodifiable(_errorLog);

  /// Handle any error and convert to AppException
  static AppException handleError(dynamic error, StackTrace? stackTrace, {String? context}) {
    final appError = _convertToAppException(error, stackTrace, context: context);
    
    _errorLog.add(appError);
    _errorController.add(appError);
    
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('ERROR [${appError.type}]: ${appError.message}');
      if (appError.originalError != null) {
        debugPrint('Original: ${appError.originalError}');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
    
    return appError;
  }

  /// Convert various errors to AppException
  static AppException _convertToAppException(dynamic error, StackTrace? stackTrace, {String? context}) {
    // Already an AppException
    if (error is AppException) {
      return error;
    }
    
    // SocketException - network issues
    if (error is SocketException) {
      return AppException(
        message: context != null ? '$context: Network connection failed' : 'Network connection failed',
        type: ErrorType.network,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    // FileSystemException - storage issues
    if (error is FileSystemException) {
      return AppException(
        message: context != null ? '$context: Storage access failed' : 'Storage access failed',
        type: ErrorType.storage,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    // FormatException - parsing issues
    if (error is FormatException) {
      return AppException(
        message: context != null ? '$context: Invalid data format' : 'Invalid data format',
        type: ErrorType.parsing,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    // Default unknown error
    return AppException(
      message: context != null ? '$context: ${error.toString()}' : error.toString(),
      type: ErrorType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, AppException error, {VoidCallback? onRetry}) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getErrorIcon(error.type), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getUserFriendlyMessage(error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error.type),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () {
                  scaffoldMessenger.hideCurrentSnackBar();
                  onRetry();
                },
              )
            : null,
      ),
    );
  }

  /// Get icon for error type
  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.storage:
        return Icons.storage;
      case ErrorType.parsing:
        return Icons.code;
      case ErrorType.ocr:
        return Icons.text_fields;
      case ErrorType.audio:
        return Icons.audiotrack;
      case ErrorType.llm:
        return Icons.memory;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  /// Get color for error type
  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.storage:
        return Colors.red;
      case ErrorType.parsing:
        return Colors.purple;
      case ErrorType.ocr:
      case ErrorType.audio:
      case ErrorType.llm:
        return Colors.blue;
      case ErrorType.unknown:
        return Colors.red;
    }
  }

  /// Get user-friendly error message
  static String _getUserFriendlyMessage(AppException error) {
    switch (error.type) {
      case ErrorType.network:
        return 'No internet connection. Please check your network.';
      case ErrorType.storage:
        return 'Storage error. Please free up space and try again.';
      case ErrorType.parsing:
        return 'Could not read file format. File may be corrupted.';
      case ErrorType.ocr:
        return 'Could not read text from image. Try a clearer photo.';
      case ErrorType.audio:
        return 'Could not transcribe audio. Try a different file.';
      case ErrorType.llm:
        return 'AI model error. Please restart the app.';
      case ErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Clear error log
  static void clearErrorLog() {
    _errorLog.clear();
  }

  /// Dispose resources
  static void dispose() {
    _errorController.close();
  }
}

/// Widget to catch and handle errors in the widget tree
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget Function(BuildContext context, AppException error)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          final error = AppException(
            message: details.exception.toString(),
            type: ErrorType.unknown,
            originalError: details.exception,
            stackTrace: details.stack,
          );
          
          if (errorBuilder != null) {
            return errorBuilder!(context, error);
          }
          
          return _defaultErrorWidget(error);
        };
        
        return child;
      },
    );
  }

  Widget _defaultErrorWidget(AppException error) {
    return Material(
      child: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.red.shade50,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ErrorHandler._getUserFriendlyMessage(error),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension to add error handling to BuildContext
extension ErrorContext on BuildContext {
  void showError(dynamic error, {VoidCallback? onRetry}) {
    final appError = error is AppException 
        ? error 
        : ErrorHandler.handleError(error, StackTrace.current);
    ErrorHandler.showErrorSnackBar(this, appError, onRetry: onRetry);
  }
}
