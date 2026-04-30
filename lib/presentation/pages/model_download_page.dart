import 'package:flutter/material.dart';

import '../../core/services/model_manager.dart';

class ModelDownloadPage extends StatefulWidget {
  const ModelDownloadPage({super.key});

  @override
  State<ModelDownloadPage> createState() => _ModelDownloadPageState();
}

class _ModelDownloadPageState extends State<ModelDownloadPage> {
  List<ModelInfo> _models = [];
  Map<String, bool> _downloadedModels = {};
  String? _activeModelId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
    
    // Listen to download progress
    ModelManager.progressNotifier.addListener(_onProgressUpdate);
  }

  @override
  void dispose() {
    ModelManager.progressNotifier.removeListener(_onProgressUpdate);
    super.dispose();
  }

  void _onProgressUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadModels() async {
    setState(() => _isLoading = true);
    
    final models = ModelManager.availableModels;
    final downloaded = <String, bool>{};
    
    for (final model in models) {
      downloaded[model.id] = await ModelManager.isModelDownloaded(model.id);
    }
    
    final activeModel = await ModelManager.getActiveModel();
    
    setState(() {
      _models = models;
      _downloadedModels = downloaded;
      _activeModelId = activeModel?.id;
      _isLoading = false;
    });
  }

  Future<void> _downloadModel(ModelInfo model) async {
    try {
      final canDownload = await ModelManager.canDownloadModel(model);
      if (!canDownload) {
        _showError('Please connect to Wi-Fi to download large models (>500MB).');
        return;
      }

      await ModelManager.downloadModel(
        model.id,
        onProgress: (progress) {
          // Progress is automatically reflected via ValueNotifier
        },
      );

      await _loadModels();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${model.name} downloaded successfully')),
        );
      }
    } catch (e) {
      _showError('Download failed: $e');
    }
  }

  Future<void> _setActiveModel(String modelId) async {
    if (!_downloadedModels[modelId]!) {
      _showError('Please download the model first.');
      return;
    }

    await ModelManager.setActiveModel(modelId);
    setState(() => _activeModelId = modelId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model activated')),
      );
    }
  }

  Future<void> _deleteModel(ModelInfo model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text('Delete ${model.name}? This will free up ${model.sizeMB} MB.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ModelManager.deleteModel(model.id);
      await _loadModels();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ModelManager.progressNotifier.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Models'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Download progress indicator
                if (progress != null && progress.status == 'downloading')
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.downloading),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Downloading ${progress.modelId}...',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text('${progress.percentage.toStringAsFixed(1)}%'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.percentage / 100,
                          minHeight: 8,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress.downloadedBytes / 1024 / 1024).toStringAsFixed(1)} MB / ${(progress.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                // Storage info
                FutureBuilder<Map<String, dynamic>>(
                  future: ModelManager.getStorageInfo(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    
                    final info = snapshot.data!;
                    return ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('Storage Used'),
                      subtitle: Text(
                        '${info['totalModels']} models • ${info['totalSizeMB']} MB',
                      ),
                      trailing: TextButton(
                        onPressed: () => _showStorageDetails(info),
                        child: const Text('Manage'),
                      ),
                    );
                  },
                ),

                const Divider(),

                // Model list
                ..._models.map((model) => _buildModelCard(model, progress)),
              ],
            ),
    );
  }

  Widget _buildModelCard(ModelInfo model, DownloadProgress? progress) {
    final isDownloaded = _downloadedModels[model.id] ?? false;
    final isActive = _activeModelId == model.id;
    final isDownloading = progress?.modelId == model.id && progress?.status == 'downloading';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.model_training,
                  color: isActive ? Colors.green : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (model.isDefault)
                        const Text(
                          'Recommended',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      if (model.isFallback)
                        const Text(
                          'Low-RAM devices',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isActive)
                  Chip(
                    label: const Text('Active'),
                    backgroundColor: Colors.green.withAlpha(50),
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              model.description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.storage, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${model.sizeMB} MB', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Icon(Icons.memory, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${model.minRamMB}+ MB RAM', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isDownloaded && !isDownloading)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _downloadModel(model),
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ),
                if (isDownloading)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: const Text('Downloading...'),
                    ),
                  ),
                if (isDownloaded) ...[
                  if (!isActive)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _setActiveModel(model.id),
                        child: const Text('Activate'),
                      ),
                    ),
                  if (isActive)
                    const Expanded(
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text('Currently Active'),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteModel(model),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStorageDetails(Map<String, dynamic> info) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if ((info['models'] as List).isEmpty)
              const Text('No models downloaded yet.')
            else
              ...((info['models'] as List).map((m) => ListTile(
                    title: Text(m['name']),
                    subtitle: Text('${m['sizeMB']} MB'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await ModelManager.deleteModel(m['id']);
                        Navigator.pop(context);
                        _loadModels();
                      },
                    ),
                  ))),
          ],
        ),
      ),
    );
  }
}
