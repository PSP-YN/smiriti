import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/objectbox_store.dart';
import 'embedding_service.dart';
import 'error_handler.dart';
import 'llm_service.dart';
import 'model_manager.dart';
import 'ocr_service.dart';
import 'secure_storage_service.dart';

/// App initialization state
enum InitState {
  idle,
  loading,
  success,
  error,
}

/// Initialization step
class InitStep {
  final String name;
  final Future<void> Function() task;
  InitState state;
  String? error;

  InitStep({
    required this.name,
    required this.task,
    this.state = InitState.idle,
    this.error,
  });
}

/// App initialization service for cold start optimization
class AppInitializer {
  static final List<InitStep> _steps = [];
  static final _progressController = StreamController<double>.broadcast();
  static final _stateController = StreamController<InitState>.broadcast();
  
  static Stream<double> get progressStream => _progressController.stream;
  static Stream<InitState> get stateStream => _stateController.stream;

  /// Initialize all services with progress tracking
  static Future<bool> initialize() async {
    _stateController.add(InitState.loading);
    
    _steps.clear();
    _steps.addAll([
      InitStep(
        name: 'Storage',
        task: () async {
          await SharedPreferences.getInstance();
        },
      ),
      InitStep(
        name: 'Security',
        task: () async {
          await SecureStorageService.initialize();
        },
      ),
      InitStep(
        name: 'Database',
        task: () async {
          try {
            await ObjectBoxStore.initialize();
          } catch (e) {
            // ObjectBox might not be generated yet
            debugPrint('ObjectBox init skipped: $e');
          }
        },
      ),
      InitStep(
        name: 'OCR Engine',
        task: () async {
          try {
            await OCRService.initialize();
          } catch (e) {
            debugPrint('OCR init warning: $e');
          }
        },
      ),
      InitStep(
        name: 'Embedding Model',
        task: () async {
          try {
            await EmbeddingService.initialize();
          } catch (e) {
            debugPrint('Embedding model not available: $e');
          }
        },
      ),
      InitStep(
        name: 'LLM Engine',
        task: () async {
          try {
            await LLMService.initialize();
          } catch (e) {
            debugPrint('LLM not available: $e');
          }
        },
      ),
      InitStep(
        name: 'Model Manager',
        task: () async {
          await ModelManager.cleanupTempFiles();
        },
      ),
    ]);

    var completed = 0;
    var hasErrors = false;

    for (final step in _steps) {
      try {
        step.state = InitState.loading;
        await step.task();
        step.state = InitState.success;
        completed++;
      } catch (e, stackTrace) {
        step.state = InitState.error;
        step.error = e.toString();
        hasErrors = true;
        
        ErrorHandler.handleError(e, stackTrace, context: step.name);
        
        // Continue even if one step fails
        debugPrint('Init step "${step.name}" failed: $e');
      }
      
      // Update progress
      final progress = completed / _steps.length;
      _progressController.add(progress);
    }

    _stateController.add(hasErrors ? InitState.error : InitState.success);
    return !hasErrors;
  }

  /// Quick initialization for background tasks
  static Future<void> initializeMinimal() async {
    try {
      await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('Minimal init error: $e');
    }
  }

  /// Get initialization report for debugging
  static Map<String, dynamic> getInitReport() {
    return {
      'totalSteps': _steps.length,
      'completedSteps': _steps.where((s) => s.state == InitState.success).length,
      'failedSteps': _steps.where((s) => s.state == InitState.error).map((s) => {
        'name': s.name,
        'error': s.error,
      }).toList(),
    };
  }

  /// Dispose all resources
  static Future<void> dispose() async {
    _progressController.close();
    _stateController.close();
    
    try {
      ObjectBoxStore.close();
    } catch (e) {
      debugPrint('Dispose error: $e');
    }
  }
}
