import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _storageUsed = '—';
  bool _loadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (mounted) setState(() => _loadingSettings = true);
    try {
      final results = await Future.wait([
        SecureStorageService.isBiometricEnabled(),
        SecureStorageService.isAppLockEnabled(),
        SecureStorageService.canAuthenticateWithBiometrics(),
        ModelManager.getActiveModel(),
        ModelManager.getStorageInfo(),
        _getDocumentDirSizeMB(),
      ]);

      final biometricEnabled = results[0] as bool;
      final appLockEnabled = results[1] as bool;
      final canBiometric = results[2] as bool;
      final activeModel = results[3] as ModelInfo?;
      final storageInfo = results[4] as Map<String, dynamic>;
      final docSizeMB = results[5] as int;

      final llmDownloaded = activeModel != null &&
          await ModelManager.isModelDownloaded(activeModel.id);
      final embeddingReady = EmbeddingService.isInitialized;

      final modelsMB = int.tryParse(
              (storageInfo['totalSizeMB'] as String?)?.split('.').first ?? '0') ??
          0;

      if (mounted) {
        setState(() {
          _biometricEnabled = biometricEnabled;
          _appLockEnabled = appLockEnabled;
          _canUseBiometrics = canBiometric;
          _embeddingModelReady = embeddingReady;
          _embeddingStatus = embeddingReady ? '✓ Ready' : 'Not downloaded';
          _llmModelName = activeModel?.name ?? 'None selected';
          _llmModelStatus = llmDownloaded ? '✓ Ready' : 'Not downloaded';
          _llmModelSize =
              activeModel != null ? '${activeModel.sizeMB} MB' : '';
          _storageUsed =
              '${modelsMB + docSizeMB} MB ($modelsMB MB models · $docSizeMB MB docs)';
          _loadingSettings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingSettings = false);
    }
  }

  Future<int> _getDocumentDirSizeMB() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/documents');
      if (!await dir.exists()) return 0;
      int total = 0;
      await for (final e in dir.list(recursive: true)) {
        if (e is File) total += await e.length();
      }
      return (total / 1024 / 1024).ceil();
    } catch (_) {
      return 0;
    }
  }

  // ── Biometric / lock toggles ──────────────────────────────────────────────

  Future<void> _toggleBiometric(bool value) async {
    if (value && !_canUseBiometrics) {
      _snack('Biometric authentication is not available on this device.');
      return;
    }
    if (value) {
      final ok = await SecureStorageService.authenticateWithBiometrics(
        reason: 'Confirm your identity to enable biometric lock',
      );
      if (!ok) {
        _snack('Authentication failed — biometric lock not enabled.');
        return;
      }
    }
    await SecureStorageService.setBiometricEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value && _canUseBiometrics) {
      final ok = await SecureStorageService.authenticateWithBiometrics(
        reason: 'Confirm your identity to enable app lock',
      );
      if (!ok) {
        _snack('Authentication failed — app lock not enabled.');
        return;
      }
    }
    await SecureStorageService.setAppLockEnabled(value);
    if (mounted) setState(() => _appLockEnabled = value);
  }

  // ── Clear data ────────────────────────────────────────────────────────────

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all documents, embeddings, AI models, and settings.\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Clearing…'),
          ],
        ),
      ),
    );

    try {
      await SecureStorageService.clearAllSecureData();
      await ObjectBoxStore.clearAll();

      final appDir = await getApplicationDocumentsDirectory();
      for (final sub in ['documents', 'models']) {
        final dir = Directory('${appDir.path}/$sub');
        if (await dir.exists()) await dir.delete(recursive: true);
      }

      if (mounted) {
        Navigator.pop(context); // close loading dialog
        _snack('All data cleared.');
        await _loadSettings();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _snack('Error: $e');
      }
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _openModelPage() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ModelDownloadPage()),
      ).then((_) => _loadSettings());

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: _loadingSettings
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                children: [
                  // ── Security & Privacy ───────────────────────────────────
                  _sectionHeader('Security & Privacy'),

                  SwitchListTile(
                    secondary: const Icon(Icons.lock_rounded),
                    title: const Text('App Lock'),
                    subtitle: const Text('Require authentication on launch'),
                    value: _appLockEnabled,
                    onChanged: _toggleAppLock,
                  ),

                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Biometric Authentication'),
                    subtitle: Text(
                      _canUseBiometrics
                          ? 'Fingerprint or face unlock'
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
                          horizontal: 72, vertical: 2),
                      child: Text(
                        'Enable App Lock first to configure biometrics.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                    ),

                  // ── AI Models ─────────────────────────────────────────────
                  _sectionHeader('AI Models'),

                  ListTile(
                    leading: Icon(
                      Icons.hub_rounded,
                      color: _embeddingModelReady
                          ? Colors.green
                          : colorScheme.onSurface.withAlpha(160),
                    ),
                    title: const Text('Embedding Model'),
                    subtitle: Text('all-MiniLM-L6-v2 · $_embeddingStatus'),
                    trailing: _embeddingModelReady
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.download_outlined),
                    onTap: _embeddingModelReady ? null : _openModelPage,
                  ),

                  ListTile(
                    leading: Icon(
                      Icons.memory_rounded,
                      color: _llmModelStatus.startsWith('✓')
                          ? Colors.green
                          : colorScheme.onSurface.withAlpha(160),
                    ),
                    title: Text(_llmModelName),
                    subtitle: Text(
                      '${_llmModelSize.isNotEmpty ? '$_llmModelSize · ' : ''}$_llmModelStatus',
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
                    onTap: _openModelPage,
                  ),

                  // ── Storage ───────────────────────────────────────────────
                  _sectionHeader('Storage'),

                  ListTile(
                    leading: const Icon(Icons.storage_rounded),
                    title: const Text('Storage Used'),
                    subtitle: Text(_storageUsed),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                      onPressed: _loadSettings,
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded,
                        color: Colors.red),
                    title: const Text('Clear All Data',
                        style: TextStyle(color: Colors.red)),
                    subtitle: const Text(
                        'Permanently delete all documents and models'),
                    onTap: _clearAllData,
                  ),

                  // ── About ─────────────────────────────────────────────────
                  _sectionHeader('About'),

                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Version'),
                    subtitle: const Text(
                        '${AppConstants.appVersion} (Build ${AppConstants.buildNumber})'),
                    trailing: TextButton(
                      onPressed: () {
                        showAboutDialog(
                          context: context,
                          applicationName: AppConstants.appName,
                          applicationVersion: AppConstants.appVersion,
                          applicationLegalese: '© 2025 Smriti. All rights reserved.',
                        );
                      },
                      child: const Text('About'),
                    ),
                  ),

                  const ListTile(
                    leading: Icon(Icons.shield_outlined),
                    title: Text('Privacy First'),
                    subtitle: Text(
                        '100% offline · Your data never leaves your device'),
                  ),

                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage()),
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.copy_outlined),
                    title: const Text('Copy App Version'),
                    onTap: () {
                      Clipboard.setData(const ClipboardData(
                          text:
                              '${AppConstants.appName} v${AppConstants.appVersion}'));
                      _snack('Copied to clipboard');
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
