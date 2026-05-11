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

  Map<String, dynamic> toJson() => {
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

  factory ModelInfo.fromJson(Map<String, dynamic> json) => ModelInfo(
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
  ModelManager._();

  static const String _modelsDir = 'models';
  static const String _activeModelKey = 'active_model_id';

  // ── Available models ──────────────────────────────────────────────────────
  static final List<ModelInfo> availableModels = [
    const ModelInfo(
      id: 'gemma-2b-q4',
      name: 'Gemma 2B (Q4)',
      description:
          'Google Gemma 2B quantized to 4-bit. Best accuracy for most queries. Requires ≥6 GB RAM.',
      sizeBytes: 1370000000,
      downloadUrl:
          'https://huggingface.co/lmstudio-community/gemma-2b-GGUF/resolve/main/gemma-2b-Q4_K_M.gguf',
      checksum: 'sha256_placeholder',
      isDefault: true,
      minRamMB: 6144,
    ),
    const ModelInfo(
      id: 'llama-3.2-1b-q4',
      name: 'Llama 3.2 1B (Q4)',
      description:
          'Meta Llama 3.2 1B quantized. Smaller footprint, works on 4 GB RAM devices.',
      sizeBytes: 700000000,
      downloadUrl:
          'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
      checksum: 'sha256_placeholder',
      isFallback: true,
      minRamMB: 4096,
    ),
    const ModelInfo(
      id: 'phi-3-mini-q4',
      name: 'Phi-3 Mini (Q4)',
      description:
          'Microsoft Phi-3 Mini. Excellent reasoning. Requires ≥8 GB RAM.',
      sizeBytes: 1900000000,
      downloadUrl:
          'https://huggingface.co/bartowski/Phi-3-mini-4k-instruct-GGUF/resolve/main/Phi-3-mini-4k-instruct-Q4_K_M.gguf',
      checksum: 'sha256_placeholder',
      minRamMB: 8192,
    ),
  ];

  static final _progressController = ValueNotifier<DownloadProgress?>(null);
  static ValueNotifier<DownloadProgress?> get progressNotifier =>
      _progressController;

  // ── Storage helpers ───────────────────────────────────────────────────────

  static Future<String> _getModelsDirPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_modelsDir');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String?> getModelPath(String modelId) async {
    final dirPath = await _getModelsDirPath();
    final file = File('$dirPath/$modelId.gguf');
    return (await file.exists()) ? file.path : null;
  }

  static Future<bool> isModelDownloaded(String modelId) async =>
      (await getModelPath(modelId)) != null;

  // ── Active model ──────────────────────────────────────────────────────────

  static Future<String?> getDefaultModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_activeModelKey);
    if (activeId != null) return getModelPath(activeId);
    final defaultModel = availableModels.firstWhere((m) => m.isDefault);
    return getModelPath(defaultModel.id);
  }

  static Future<ModelInfo?> getActiveModel() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_activeModelKey);
    if (activeId == null) {
      return availableModels.firstWhere((m) => m.isDefault);
    }
    try {
      return availableModels.firstWhere((m) => m.id == activeId);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setActiveModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeModelKey, modelId);
  }

  // ── Download ──────────────────────────────────────────────────────────────

  /// Returns true if there is any internet connection (WiFi or cellular).
  static Future<bool> hasInternetConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Returns true if the device can reach the internet, regardless of
  /// connection type (WiFi, mobile data, ethernet, VPN, etc.).
  static Future<bool> canDownloadModel(ModelInfo model) async {
    // Only require *some* internet — no WiFi restriction
    final hasNet = await hasInternetConnection();
    if (!hasNet) return false;

    // Rough available-space check (files in models dir are .gguf, stat.size
    // gives directory metadata size, not free disk — kept for compatibility)
    final dirPath = await _getModelsDirPath();
    final stat = await FileStat.stat(dirPath);
    if (stat.size > 0 && stat.size < model.sizeBytes) return false;

    return true;
  }

  static Future<void> downloadModel(
    String modelId, {
    void Function(DownloadProgress)? onProgress,
  }) async {
    final model = availableModels.firstWhere((m) => m.id == modelId);

    // Only check for internet — no WiFi-only requirement
    if (!await hasInternetConnection()) {
      throw Exception('No internet connection. Please connect to the internet and try again.');
    }

    final dirPath = await _getModelsDirPath();
    final tempFile = File('$dirPath/$modelId.tmp');
    final finalFile = File('$dirPath/$modelId.gguf');

    try {
      _updateProgress(modelId, 0, model.sizeBytes, 'downloading');

      final request = http.Request('GET', Uri.parse(model.downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? model.sizeBytes;
      var downloadedBytes = 0;

      final sink = tempFile.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        final pct = downloadedBytes / totalBytes * 100;
        _updateProgress(modelId, downloadedBytes, totalBytes, 'downloading');
        onProgress?.call(DownloadProgress(
          modelId: modelId,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
          percentage: pct,
          status: 'downloading',
        ));
      }
      await sink.flush();
      await sink.close();

      // Verify checksum (skip for placeholder hashes)
      if (model.checksum != 'sha256_placeholder') {
        final valid = await _verifyChecksum(tempFile, model.checksum);
        if (!valid) {
          await tempFile.delete();
          throw Exception('Checksum verification failed. Download may be corrupt.');
        }
      }

      await tempFile.rename(finalFile.path);

      _updateProgress(modelId, totalBytes, totalBytes, 'completed');
      onProgress?.call(DownloadProgress(
        modelId: modelId,
        downloadedBytes: totalBytes,
        totalBytes: totalBytes,
        percentage: 100,
        status: 'completed',
      ));

      // Auto-set as active if no model is currently active
      final currentActive = await getActiveModel();
      final currentDownloaded = currentActive != null
          ? await isModelDownloaded(currentActive.id)
          : false;
      if (!currentDownloaded) {
        await setActiveModel(modelId);
      }
    } catch (e) {
      _updateProgress(modelId, 0, model.sizeBytes, 'error',
          error: e.toString());
      if (await tempFile.exists()) await tempFile.delete();
      rethrow;
    }
  }

  static Future<bool> _verifyChecksum(File file, String expected) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString() == expected;
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

  // ── Delete ────────────────────────────────────────────────────────────────

  static Future<void> deleteModel(String modelId) async {
    final path = await getModelPath(modelId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }

    final active = await getActiveModel();
    if (active?.id == modelId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeModelKey);
    }
  }

  // ── Storage info ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStorageInfo() async {
    final dirPath = await _getModelsDirPath();
    final dir = Directory(dirPath);

    if (!await dir.exists()) {
      return {'totalModels': 0, 'totalSizeBytes': 0, 'totalSizeMB': '0.0', 'models': []};
    }

    final models = <Map<String, dynamic>>[];
    var totalSize = 0;

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.gguf')) {
        final stat = await entity.stat();
        final modelId = entity.path.split('/').last.replaceAll('.gguf', '');
        final info = availableModels.firstWhere(
          (m) => m.id == modelId,
          orElse: () => ModelInfo(
            id: modelId,
            name: modelId,
            description: '',
            sizeBytes: stat.size,
            downloadUrl: '',
            checksum: '',
          ),
        );
        models.add({
          'id': modelId,
          'name': info.name,
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

  // ── Cleanup ───────────────────────────────────────────────────────────────

  static Future<void> cleanupTempFiles() async {
    try {
      final dirPath = await _getModelsDirPath();
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.tmp')) {
          await entity.delete();
          debugPrint('ModelManager: cleaned up ${entity.path}');
        }
      }
    } catch (e) {
      debugPrint('ModelManager.cleanupTempFiles error: $e');
    }
  }
}
