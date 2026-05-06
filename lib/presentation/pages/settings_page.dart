import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/embedding_service.dart';
import '../../core/services/llm_service.dart';
import '../../core/services/model_manager.dart';
import '../../core/services/secure_storage_service.dart';
import '../../data/objectbox_store.dart';
import 'model_download_page.dart';
import 'privacy_policy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricEnabled = false;
  bool _appLockEnabled = false;
  bool _canUseBiometrics = false;
  bool _embeddingModelReady = false;
  String _embeddingStatus = 'Not downloaded';
  String _llmModelName = 'None';
  String _llmModelStatus = 'Not downloaded';
  String _llmModelSize = '';
  String _storageUsed = 'Calculating...';
  bool _loadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loadingSettings = true);
    try {
      final biometricEnabled = await SecureStorageService.isBiometricEnabled();
      final appLockEnabled = await SecureStorageService.isAppLockEnabled();
      final canBiometric = await SecureStorageService.canAuthenticateWithBiometrics();
      final embeddingReady = EmbeddingService.isInitialized;
      final activeModel = await ModelManager.getActiveModel();
      final llmDownloaded = activeModel != null
          ? await ModelManager.isModelDownloaded(activeModel.id)
          : false;
      final storageInfo = await ModelManager.getStorageInfo();
      final docSize = await _getDocumentDirSize();

      if (mounted) {
        setState(() {
          _biometricEnabled = biometricEnabled;
          _appLockEnabled = appLockEnabled;
          _canUseBiometrics = canBiometric;
          _embeddingModelReady = embeddingReady;
          _embeddingStatus = embeddingReady ? 'Ready' : 'Not downloaded';
          _llmModelName = activeModel?.name ?? 'None selected';
          _llmModelStatus = llmDownloaded ? 'Ready' : 'Not downloaded';
          _llmModelSize = activeModel != null ? '${activeModel.sizeMB} MB' : '';
          final modelsMB = storageInfo['totalSizeMB'] as int? ?? 0;
          final docMB = docSize;
          _storageUsed = '${modelsMB + docMB} MB total'
              ' ($modelsMB MB models, $docMB MB documents)';
          _loadingSettings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingSettings = false);
    }
  }

  Future<int> _getDocumentDirSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/documents');
      if (!await docsDir.exists()) return 0;
      int total = 0;
      await for (final entity in docsDir.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return (total / 1024 / 1024).ceil();
    } catch (_) {
      return 0;
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value && !_canUseBiometrics) {
      _showSnack('Biometric authentication not available on this device');
      return;
    }
    if (value) {
      // Verify biometric before enabling
      final ok = await SecureStorageService.authenticateWithBiometrics(
        reason: 'Confirm your identity to enable biometric lock',
      );
      if (!ok) {
        _showSnack('Authentication failed — biometric lock not enabled');
        return;
      }
    }
    await SecureStorageService.setBiometricEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value && _canUseBiometrics) {
      // Verify identity before enabling lock
      final ok = await SecureStorageService.authenticateWithBiometrics(
        reason: 'Confirm your identity to enable app lock',
      );
      if (!ok) {
        _showSnack('Authentication failed — app lock not enabled');
        return;
      }
    }
    await SecureStorageService.setAppLockEnabled(value);
    if (mounted) setState(() => _appLockEnabled = value);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all documents, embeddings, AI models, and settings.\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Clearing all data...'),
          ],
        ),
      ),
    );

    try {
      // 1. Clear secure storage
      await SecureStorageService.clearAllSecureData();

      // 2. Clear ObjectBox (documents + chunks)
      await ObjectBoxStore.clearAll();

      // 3. Delete document files from disk
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/documents');
      if (await docsDir.exists()) await docsDir.delete(recursive: true);

      // 4. Delete downloaded AI models
      final modelsDir = Directory('${appDir.path}/models');
      if (await modelsDir.exists()) await modelsDir.delete(recursive: true);

      if (mounted) {
        Navigator.pop(context); // close loading dialog
        _showSnack('All data cleared successfully');
        await _loadSettings();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnack('Error clearing data: $e');
      }
    }
  }

  void _showSnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _loadingSettings
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                children: [
                  // ── Security & Privacy ──────────────────────────────────
                  _sectionHeader('Security & Privacy'),

                  SwitchListTile(
                    secondary: const Icon(Icons.lock),
                    title: const Text('App Lock'),
                    subtitle: const Text('Require authentication on app launch'),
                    value: _appLockEnabled,
                    onChanged: _toggleAppLock,
                  ),

                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Biometric Authentication'),
                    subtitle: Text(
                      _canUseBiometrics
                          ? 'Use fingerprint or face to unlock'
                          : 'Not available on this device',
                    ),
                    value: _biometricEnabled,
                    onChanged: _canUseBiometrics && _appLockEnabled
                        ? _toggleBiometric
                        : null,
                  ),

                  if (!_appLockEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Text(
                        'Enable App Lock first to configure biometrics.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(120),
                        ),
                      ),
                    ),

                  // ── AI Models ───────────────────────────────────────────
                  _sectionHeader('AI Models'),

                  ListTile(
                    leading: const Icon(Icons.model_training),
                    title: const Text('Embedding Model'),
                    subtitle: Text(
                        'all-MiniLM-L6-v2 — $_embeddingStatus'),
                    trailing: _embeddingModelReady
                        ? const Icon(Icons.check_circle,
                            color: Colors.green)
                        : const Icon(Icons.download_outlined),
                    onTap: _embeddingModelReady
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ModelDownloadPage()),
                            ).then((_) => _loadSettings());
                          },
                  ),

                  ListTile(
                    leading: const Icon(Icons.memory),
                    title: const Text('LLM Model'),
                    subtitle: Text(
                      '$_llmModelName'
                      '${_llmModelSize.isNotEmpty ? " \u2022 $_llmModelSize" : ""}'
                      ' \u2022 $_llmModelStatus',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (LLMService.isInitialized)
                          const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ModelDownloadPage()),
                      ).then((_) => _loadSettings());
                    },
                  ),

                  // ── Storage ─────────────────────────────────────────────
                  _sectionHeader('Storage'),

                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('Storage Used'),
                    subtitle: Text(_storageUsed),
                    trailing: TextButton(
                      onPressed: _loadSettings,
                      child: const Text('Refresh'),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.delete_forever,
                        color: Colors.red),
                    title: const Text(
                      'Clear All Data',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Permanently delete all documents and models'),
                    onTap: _clearAllData,
                  ),

                  // ── About ───────────────────────────────────────────────
                  _sectionHeader('About'),

                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Version'),
                    subtitle: Text('${AppConstants.appVersion} (Build ${AppConstants.buildNumber})'),
                  ),

                  const ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('Privacy First'),
                    subtitle: Text('100% offline — your data never leaves your device'),
                  ),

                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyPage()),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
