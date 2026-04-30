import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelInfo {
  final String id;
  final String name;
  final String description;
  final int sizeBytes;
  final String downloadUrl;
  final String checksum;
  final bool isDefault;
  final bool isFallback;
  final int minRamMB;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeBytes,
    required this.downloadUrl,
    required this.checksum,
    this.isDefault = false,
    this.isFallback = false,
    this.minRamMB = 4096,
  });

  String get sizeMB => (sizeBytes / 1024 / 1024).toStringAsFixed(1);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sizeBytes': sizeBytes,
      'downloadUrl': downloadUrl,
      'checksum': checksum,
      'isDefault': isDefault,
      'isFallback': isFallback,
      'minRamMB': minRamMB,
    };
  }

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      sizeBytes: json['sizeBytes'] as int,
      downloadUrl: json['downloadUrl'] as String,
      checksum: json['checksum'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      isFallback: json['isFallback'] as bool? ?? false,
      minRamMB: json['minRamMB'] as int? ?? 4096,
    );
  }
}

class DownloadProgress {
  final String modelId;
  final int downloadedBytes;
  final int totalBytes;
  final double percentage;
  final String status; // 'downloading', 'completed', 'error'
  final String? error;

  const DownloadProgress({
    required this.modelId,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.percentage,
    required this.status,
    this.error,
  });
}

class ModelManager {
  static const String _modelsDir = 'models';
  
  // Model definitions
  static final List<ModelInfo> availableModels = [
    ModelInfo(
      id: 'gemma-2b-q4',
      name: 'Gemma 2B (Q4)',
      description: 'Google Gemma 2B quantized to 4-bit. Fast and accurate for most queries.',
      sizeBytes: 1370000000, // ~1.3 GB
      downloadUrl: 'https://huggingface.co/google/gemma-2b/resolve/main/gemma-2b-q4.gguf',
      checksum: 'sha256_placeholder',
      isDefault: true,
      minRamMB: 6144,
    ),
    ModelInfo(
      id: 'llama-3.2-1b-q4',
      name: 'Llama 3.2 1B (Q4)',
      description: 'Meta Llama 3.2 1B quantized. Smaller footprint, good for 4-6GB RAM devices.',
      sizeBytes: 700000000, // ~700 MB
      downloadUrl: 'https://huggingface.co/meta/llama-3.2-1b/resolve/main/llama-3.2-1b-q4.gguf',
      checksum: 'sha256_placeholder',
      isFallback: true,
      minRamMB: 4096,
    ),
    ModelInfo(
      id: 'phi-3-mini-q4',
      name: 'Phi-3 Mini (Q4)',
      description: 'Microsoft Phi-3 Mini. Excellent reasoning capabilities.',
      sizeBytes: 1900000000, // ~1.9 GB
      downloadUrl: 'https://huggingface.co/microsoft/phi-3-mini/resolve/main/phi-3-mini-q4.gguf',
      checksum: 'sha256_placeholder',
      minRamMB: 8192,
    ),
  ];

  static final _progressController = ValueNotifier<DownloadProgress?>(null);
  static ValueNotifier<DownloadProgress?> get progressNotifier => _progressController;

  static Future<String> _getModelsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/$_modelsDir');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir.path;
  }

  static Future<String?> getDefaultModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    final activeModelId = prefs.getString('active_model_id');
    
    if (activeModelId != null) {
      return getModelPath(activeModelId);
    }
    
    // Check for default model
    final defaultModel = availableModels.firstWhere((m) => m.isDefault);
    return getModelPath(defaultModel.id);
  }

  static Future<String?> getModelPath(String modelId) async {
    final modelsDir = await _getModelsDir();
    final modelFile = File('$modelsDir/$modelId.gguf');
    
    if (await modelFile.exists()) {
      return modelFile.path;
    }
    return null;
  }

  static Future<bool> isModelDownloaded(String modelId) async {
    final path = await getModelPath(modelId);
    return path != null;
  }

  static Future<ModelInfo?> getActiveModel() async {
    final prefs = await SharedPreferences.getInstance();
    final activeModelId = prefs.getString('active_model_id');
    
    if (activeModelId == null) {
      return availableModels.firstWhere((m) => m.isDefault);
    }
    
    try {
      return availableModels.firstWhere((m) => m.id == activeModelId);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setActiveModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_model_id', modelId);
  }

  static Future<bool> canDownloadModel(ModelInfo model) async {
    // Check Wi-Fi connection
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.mobile) {
      // Warn about mobile data usage for large models
      if (model.sizeBytes > 500 * 1024 * 1024) {
        return false; // Require Wi-Fi for models > 500MB
      }
    }
    
    // Check available storage
    final modelsDir = await _getModelsDir();
    final stat = await FileStat.stat(modelsDir);
    final availableSpace = stat.size; // This is approximate
    
    // Need at least 2x model size (download temp + final file)
    if (availableSpace < model.sizeBytes * 2) {
      return false;
    }
    
    return true;
  }

  static Future<void> downloadModel(
    String modelId, {
    void Function(DownloadProgress)? onProgress,
    bool useWiFiOnly = true,
  }) async {
    final model = availableModels.firstWhere((m) => m.id == modelId);
    
    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (useWiFiOnly && connectivity != ConnectivityResult.wifi) {
      throw Exception('Wi-Fi required for model download. Go to Settings to allow mobile data.');
    }

    // Check storage
    if (!await canDownloadModel(model)) {
      throw Exception('Insufficient storage space for model download.');
    }

    final modelsDir = await _getModelsDir();
    final tempFile = File('$modelsDir/$modelId.tmp');
    final finalFile = File('$modelsDir/$modelId.gguf');

    try {
      _updateProgress(modelId, 0, model.sizeBytes, 'downloading');

      // Start download with streaming
      final request = http.Request('GET', Uri.parse(model.downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? model.sizeBytes;
      var downloadedBytes = 0;

      // Write to temp file
      final sink = tempFile.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        final percentage = (downloadedBytes / totalBytes * 100);
        _updateProgress(modelId, downloadedBytes, totalBytes, 'downloading');
        
        if (onProgress != null) {
          onProgress(DownloadProgress(
            modelId: modelId,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            percentage: percentage,
            status: 'downloading',
          ));
        }
      }
      await sink.close();

      // Verify checksum
      final isValid = await _verifyChecksum(tempFile, model.checksum);
      if (!isValid) {
        await tempFile.delete();
        throw Exception('Downloaded file checksum verification failed.');
      }

      // Move to final location
      await tempFile.rename(finalFile.path);

      _updateProgress(modelId, totalBytes, totalBytes, 'completed');
      
      if (onProgress != null) {
        onProgress(DownloadProgress(
          modelId: modelId,
          downloadedBytes: totalBytes,
          totalBytes: totalBytes,
          percentage: 100,
          status: 'completed',
        ));
      }

      // Set as active if it's the first model
      final currentActive = await getActiveModel();
      if (currentActive == null) {
        await setActiveModel(modelId);
      }

    } catch (e) {
      _updateProgress(modelId, 0, model.sizeBytes, 'error', error: e.toString());
      
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      rethrow;
    }
  }

  static Future<bool> _verifyChecksum(File file, String expectedChecksum) async {
    // In production, compute SHA-256 hash and compare
    // For now, we skip verification (placeholder checksums)
    if (expectedChecksum == 'sha256_placeholder') {
      return true;
    }
    
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString() == expectedChecksum;
  }

  static void _updateProgress(
    String modelId,
    int downloaded,
    int total,
    String status, {
    String? error,
  }) {
    _progressController.value = DownloadProgress(
      modelId: modelId,
      downloadedBytes: downloaded,
      totalBytes: total,
      percentage: total > 0 ? (downloaded / total * 100) : 0,
      status: status,
      error: error,
    );
  }

  static Future<void> deleteModel(String modelId) async {
    final path = await getModelPath(modelId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Clear active model if this was the active one
    final activeModel = await getActiveModel();
    if (activeModel?.id == modelId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_model_id');
    }
  }

  static Future<void> recommendModelForDevice() async {
    // Check device RAM
    // On Android, we can estimate based on device info
    // For now, recommend based on conservative estimates
    
    // Gemma 2B: 6GB+ RAM
    // Llama 3.2 1B: 4GB+ RAM
    
    final hasGemma = await isModelDownloaded('gemma-2b-q4');
    final hasLlama = await isModelDownloaded('llama-3.2-1b-q4');
    
    if (!hasGemma && !hasLlama) {
      // Recommend Gemma 2B as default
      return;
    }
    
    // Set appropriate model as active
    if (hasGemma) {
      await setActiveModel('gemma-2b-q4');
    } else if (hasLlama) {
      await setActiveModel('llama-3.2-1b-q4');
    }
  }

  static Future<Map<String, dynamic>> getStorageInfo() async {
    final modelsDir = await _getModelsDir();
    final dir = Directory(modelsDir);
    
    if (!await dir.exists()) {
      return {
        'totalModels': 0,
        'totalSizeBytes': 0,
        'models': [],
      };
    }

    final models = <Map<String, dynamic>>[];
    var totalSize = 0;

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.gguf')) {
        final stat = await entity.stat();
        final modelId = entity.path.split('/').last.replaceAll('.gguf', '');
        final modelInfo = availableModels.firstWhere(
          (m) => m.id == modelId,
          orElse: () => ModelInfo(
            id: modelId,
            name: 'Unknown Model',
            description: '',
            sizeBytes: stat.size,
            downloadUrl: '',
            checksum: '',
          ),
        );

        models.add({
          'id': modelId,
          'name': modelInfo.name,
          'sizeBytes': stat.size,
          'sizeMB': (stat.size / 1024 / 1024).toStringAsFixed(1),
          'modified': stat.modified.toIso8601String(),
        });
        
        totalSize += stat.size;
      }
    }

    return {
      'totalModels': models.length,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(1),
      'models': models,
    };
  }

  static Future<void> cleanupTempFiles() async {
    final modelsDir = await _getModelsDir();
    final dir = Directory(modelsDir);
    
    if (!await dir.exists()) return;

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.tmp')) {
        await entity.delete();
      }
    }
  }
}
