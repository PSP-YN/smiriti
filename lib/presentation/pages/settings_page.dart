import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/embedding_service.dart';
import '../../core/services/model_manager.dart';
import '../../core/services/secure_storage_service.dart';
import '../../data/objectbox_store.dart';
import '../../main.dart';
import 'model_download_page.dart';
import 'privacy_policy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _activeProvider = 'local';
  bool _embeddingModelReady = false;
  String _embeddingStatus = 'Not downloaded';
  String _llmModelName = 'None';
  String _llmModelStatus = 'Not downloaded';
  String _llmModelSize = '';
  String _storageUsed = '—';
  bool _loadingSettings = true;
  ThemeMode _themeMode = ThemeMode.system;
  bool _appLockEnabled = false;

  final _openaiController = TextEditingController();
  final _anthropicController = TextEditingController();
  final _googleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _openaiController.dispose();
    _anthropicController.dispose();
    _googleController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (mounted) setState(() => _loadingSettings = true);
    try {
      final secureResults = await Future.wait([
        SecureStorageService.getActiveProvider(),
        SecureStorageService.getOpenAIKey(),
        SecureStorageService.getAnthropicKey(),
        SecureStorageService.getGoogleKey(),
        SecureStorageService.isAppLockEnabled(),
      ]);

      final activeProvider = secureResults[0] as String;
      final openaiKey = secureResults[1] as String?;
      final anthropicKey = secureResults[2] as String?;
      final googleKey = secureResults[3] as String?;
      final appLockEnabled = secureResults[4] as bool;

      if (openaiKey != null) _openaiController.text = openaiKey;
      if (anthropicKey != null) _anthropicController.text = anthropicKey;
      if (googleKey != null) _googleController.text = googleKey;

      final activeModel = await ModelManager.getActiveModel();
      final llmDownloaded = activeModel != null &&
          await ModelManager.isModelDownloaded(activeModel.id);
      final embeddingReady = EmbeddingService.isInitialized;

      final storageInfo = await ModelManager.getStorageInfo();
      final modelsMB = int.tryParse(
              (storageInfo['totalSizeMB'] as String?)?.split('.').first ?? '0') ??
          0;
      final docSizeMB = await _getDocumentDirSizeMB();

      final prefs = await SharedPreferences.getInstance();
      final themeModeStr = prefs.getString('theme_mode') ?? 'system';

      if (mounted) {
        setState(() {
          _activeProvider = activeProvider;
          _embeddingModelReady = embeddingReady;
          _embeddingStatus = embeddingReady ? '✓ Ready' : 'Not downloaded';
          _llmModelName = activeModel?.name ?? 'None selected';
          _llmModelStatus = llmDownloaded ? '✓ Ready' : 'Not downloaded';
          _llmModelSize =
              activeModel != null ? '${activeModel.sizeMB} MB' : '';
          _storageUsed =
              '${modelsMB + docSizeMB} MB ($modelsMB MB models · $docSizeMB MB docs)';
          _themeMode = themeModeStr == 'light'
              ? ThemeMode.light
              : themeModeStr == 'dark'
                  ? ThemeMode.dark
                  : ThemeMode.system;
          _appLockEnabled = appLockEnabled;
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

  Future<void> _saveProvider(String? value) async {
    if (value == null) return;
    await SecureStorageService.setActiveProvider(value);
    setState(() => _activeProvider = value);
  }

  Future<void> _saveAPIKey(String provider, String key) async {
    if (provider == 'openai') await SecureStorageService.setOpenAIKey(key);
    if (provider == 'anthropic') await SecureStorageService.setAnthropicKey(key);
    if (provider == 'google') await SecureStorageService.setGoogleKey(key);
    _snack('API Key saved for $provider');
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await prefs.setString('theme_mode', val);
    setState(() => _themeMode = mode);
    if (mounted) {
      context.findAncestorStateOfType<SmritiAppState>()?.setThemeMode(mode);
    }
  }

  Future<void> _toggleAppLock(bool enabled) async {
    if (enabled) {
      final canAuth = await SecureStorageService.canAuthenticateWithBiometrics();
      if (!canAuth) {
        _snack('Biometric authentication is not available on this device');
        return;
      }
      final authenticated = await SecureStorageService.authenticateWithBiometrics(
        reason: 'Enable app lock',
      );
      if (!authenticated) {
        _snack('Authentication failed. App lock not enabled.');
        return;
      }
    }
    await SecureStorageService.setAppLockEnabled(enabled);
    setState(() => _appLockEnabled = enabled);
    _snack(enabled ? 'App lock enabled' : 'App lock disabled');
  }

  Future<void> _showPinDialog() async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    final hasPin = await SecureStorageService.hasAppPin();
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hasPin ? 'Change PIN' : 'Set PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPin)
              TextField(
                controller: oldPinController,
                decoration: const InputDecoration(labelText: 'Current PIN', border: OutlineInputBorder()),
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            if (hasPin) const SizedBox(height: 8),
            TextField(
              controller: newPinController,
              decoration: const InputDecoration(labelText: 'New PIN', border: OutlineInputBorder()),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPinController,
              decoration: const InputDecoration(labelText: 'Confirm PIN', border: OutlineInputBorder()),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (save != true) return;

    if (hasPin) {
      final valid = await SecureStorageService.verifyAppPin(oldPinController.text);
      if (!valid) { _snack('Current PIN is incorrect'); return; }
    }

    if (newPinController.text.length < 4) { _snack('PIN must be at least 4 digits'); return; }
    if (newPinController.text != confirmPinController.text) { _snack('PINs do not match'); return; }

    if (newPinController.text.isEmpty) {
      await SecureStorageService.removeAppPin();
      _snack('PIN removed');
    } else {
      await SecureStorageService.setAppPin(newPinController.text);
      _snack('PIN saved');
    }
  }

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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Clearing…')],
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
        Navigator.pop(context);
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

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _openModelPage() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ModelDownloadPage()),
      ).then((_) => _loadSettings());

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
                  _sectionHeader('Appearance'),
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('Theme'),
                    subtitle: Text(_themeMode == ThemeMode.system ? 'Follow system' : _themeMode == ThemeMode.light ? 'Light' : 'Dark'),
                    trailing: ToggleButtons(
                      isSelected: [
                        _themeMode == ThemeMode.system,
                        _themeMode == ThemeMode.light,
                        _themeMode == ThemeMode.dark,
                      ],
                      onPressed: (i) {
                        final modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
                        _setThemeMode(modes[i]);
                      },
                      borderRadius: BorderRadius.circular(8),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                      children: const [
                        Icon(Icons.brightness_auto, size: 18),
                        Icon(Icons.light_mode, size: 18),
                        Icon(Icons.dark_mode, size: 18),
                      ],
                    ),
                  ),

                  _sectionHeader('Security'),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Biometric Lock'),
                    subtitle: const Text('Require fingerprint/face to unlock'),
                    value: _appLockEnabled,
                    onChanged: _toggleAppLock,
                  ),
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: const Text('PIN Lock'),
                    subtitle: const Text('Set or change app PIN'),
                    trailing: TextButton(
                      onPressed: _showPinDialog,
                      child: const Text('Set PIN'),
                    ),
                  ),

                  _sectionHeader('AI Provider'),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: DropdownButtonFormField<String>(
                      value: _activeProvider,
                      decoration: const InputDecoration(
                        labelText: 'Active AI Provider',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'local', child: Text('Local (Offline)')),
                        DropdownMenuItem(value: 'openai', child: Text('OpenAI (Cloud)')),
                        DropdownMenuItem(value: 'anthropic', child: Text('Anthropic (Cloud)')),
                        DropdownMenuItem(value: 'google', child: Text('Google Gemini (Cloud)')),
                      ],
                      onChanged: _saveProvider,
                    ),
                  ),

                  if (_activeProvider == 'openai')
                    _apiKeyTile('OpenAI API Key', _openaiController, 'openai'),
                  if (_activeProvider == 'anthropic')
                    _apiKeyTile('Anthropic API Key', _anthropicController, 'anthropic'),
                  if (_activeProvider == 'google')
                    _apiKeyTile('Google AI API Key', _googleController, 'google'),

                  const Divider(),

                  _sectionHeader('Local AI Models'),

                  ListTile(
                    leading: Icon(
                      Icons.hub_rounded,
                      color: _embeddingModelReady ? Colors.green : colorScheme.onSurface.withAlpha(160),
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
                      color: _llmModelStatus.startsWith('✓') ? Colors.green : colorScheme.onSurface.withAlpha(160),
                    ),
                    title: Text(_llmModelName),
                    subtitle: Text('${_llmModelSize.isNotEmpty ? '$_llmModelSize · ' : ''}$_llmModelStatus'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openModelPage,
                  ),

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
                    leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                    title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Permanently delete all documents and models'),
                    onTap: _clearAllData,
                  ),

                  _sectionHeader('About'),

                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Version'),
                    subtitle: const Text('${AppConstants.appVersion} (Build ${AppConstants.buildNumber})'),
                  ),

                  const ListTile(
                    leading: Icon(Icons.shield_outlined),
                    title: Text('Privacy First'),
                    subtitle: Text('100% offline · Your data never leaves your device'),
                  ),

                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
                  ),

                  ListTile(
                    leading: const Icon(Icons.copy_outlined),
                    title: const Text('Copy App Version'),
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: '${AppConstants.appName} v${AppConstants.appVersion}'));
                      _snack('Copied to clipboard');
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _apiKeyTile(String label, TextEditingController controller, String provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              obscureText: true,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveAPIKey(provider, controller.text),
            tooltip: 'Save key',
          ),
        ],
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
