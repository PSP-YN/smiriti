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
    ModelManager.progressNotifier.addListener(_onProgressUpdate);
  }

  @override
  void dispose() {
    ModelManager.progressNotifier.removeListener(_onProgressUpdate);
    super.dispose();
  }

  void _onProgressUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadModels() async {
    if (mounted) setState(() => _isLoading = true);
    final models = ModelManager.availableModels;
    final downloaded = <String, bool>{};
    for (final m in models) {
      downloaded[m.id] = await ModelManager.isModelDownloaded(m.id);
    }
    final active = await ModelManager.getActiveModel();
    if (mounted) {
      setState(() {
        _models = models;
        _downloadedModels = downloaded;
        _activeModelId = active?.id;
        _isLoading = false;
      });
    }
  }

  // ── Download ──────────────────────────────────────────────────────────────

  Future<void> _downloadModel(ModelInfo model) async {
    final hasNet = await ModelManager.hasInternetConnection();
    if (!hasNet) {
      _showError(
          'No internet connection. Connect to WiFi or mobile data and try again.');
      return;
    }

    try {
      await ModelManager.downloadModel(model.id);
      await _loadModels();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${model.name} downloaded successfully ✓'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      _showError('Download failed: ${e.toString().split('\n').first}');
    }
  }

  Future<void> _setActiveModel(String modelId) async {
    if (_downloadedModels[modelId] != true) {
      _showError('Please download the model first.');
      return;
    }
    await ModelManager.setActiveModel(modelId);
    if (mounted) setState(() => _activeModelId = modelId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model activated ✓')),
      );
    }
  }

  Future<void> _deleteModel(ModelInfo model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Model'),
        content:
            Text('Delete ${model.name}? This will free ~${model.sizeMB} MB.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final progress = ModelManager.progressNotifier.value;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Models'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // ── Info banner ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(60),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: colorScheme.primary.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: colorScheme.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Models can be downloaded over WiFi or mobile data. '
                            'No WiFi required.',
                            style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Active download progress ──────────────────────────────────
                if (progress != null && progress.status == 'downloading')
                  _DownloadProgressBanner(progress: progress),

                // ── Storage summary ───────────────────────────────────────────
                FutureBuilder<Map<String, dynamic>>(
                  future: ModelManager.getStorageInfo(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final info = snap.data!;
                    return ListTile(
                      leading: const Icon(Icons.storage_rounded),
                      title: const Text('Downloaded models'),
                      subtitle: Text(
                          '${info['totalModels']} models · ${info['totalSizeMB']} MB'),
                    );
                  },
                ),

                const Divider(height: 1),

                // ── Model cards ───────────────────────────────────────────────
                ..._models.map((m) => _ModelCard(
                      model: m,
                      isDownloaded: _downloadedModels[m.id] ?? false,
                      isActive: _activeModelId == m.id,
                      isDownloading: progress?.modelId == m.id &&
                          progress?.status == 'downloading',
                      progressPct: (progress?.modelId == m.id)
                          ? progress?.percentage
                          : null,
                      onDownload: () => _downloadModel(m),
                      onActivate: () => _setActiveModel(m.id),
                      onDelete: () => _deleteModel(m),
                    )),
              ],
            ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DownloadProgressBanner extends StatelessWidget {
  final DownloadProgress progress;
  const _DownloadProgressBanner({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dlMB = (progress.downloadedBytes / 1024 / 1024).toStringAsFixed(1);
    final totalMB = (progress.totalBytes / 1024 / 1024).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(70),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.downloading_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Downloading ${progress.modelId}…',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${progress.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.percentage / 100,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text('$dlMB MB / $totalMB MB',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final ModelInfo model;
  final bool isDownloaded;
  final bool isActive;
  final bool isDownloading;
  final double? progressPct;
  final VoidCallback onDownload;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const _ModelCard({
    required this.model,
    required this.isDownloaded,
    required this.isActive,
    required this.isDownloading,
    required this.progressPct,
    required this.onDownload,
    required this.onActivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? colorScheme.primary.withAlpha(100)
              : colorScheme.outline.withAlpha(60),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.memory_rounded,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurface.withAlpha(160),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.name,
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (model.isDefault)
                        Text('⭐ Recommended',
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.amber.shade700)),
                      if (model.isFallback)
                        Text('Low-RAM devices',
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.orange.shade600)),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Active',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),

            const SizedBox(height: 10),
            Text(model.description, style: textTheme.bodySmall),

            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.storage_rounded,
                    size: 14, color: colorScheme.outline),
                const SizedBox(width: 4),
                Text('${model.sizeMB} MB',
                    style: textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.memory_rounded,
                    size: 14, color: colorScheme.outline),
                const SizedBox(width: 4),
                Text('≥${model.minRamMB} MB RAM',
                    style: textTheme.bodySmall),
              ],
            ),

            // ── Download progress ──────────────────────────────────────────
            if (isDownloading && progressPct != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (progressPct ?? 0) / 100,
                  minHeight: 6,
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ── Action row ─────────────────────────────────────────────────
            Row(
              children: [
                if (!isDownloaded && !isDownloading)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download'),
                    ),
                  ),

                if (isDownloading)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: const Text('Downloading…'),
                    ),
                  ),

                if (isDownloaded) ...[
                  if (!isActive)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onActivate,
                        child: const Text('Activate'),
                      ),
                    ),
                  if (isActive)
                    const Expanded(
                      child: OutlinedButton(
                        onPressed: null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 16, color: Colors.green),
                            SizedBox(width: 6),
                            Text('Active',
                                style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: Colors.red,
                    tooltip: 'Delete model',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
