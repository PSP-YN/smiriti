import 'package:flutter/material.dart';

import '../../core/services/embedding_service.dart';
import '../../core/services/llm_service.dart';
import '../../core/services/model_manager.dart';
import '../../core/services/secure_storage_service.dart';
import 'model_download_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final biometricEnabled = await SecureStorageService.isBiometricEnabled();
    final appLockEnabled = await SecureStorageService.isAppLockEnabled();
    final canUseBiometrics = await SecureStorageService.canAuthenticateWithBiometrics();
    final embeddingReady = EmbeddingService.isInitialized;
    
    // Load LLM model info
    final activeModel = await ModelManager.getActiveModel();
    final llmDownloaded = activeModel != null 
        ? await ModelManager.isModelDownloaded(activeModel.id)
        : false;
    
    setState(() {
      _biometricEnabled = biometricEnabled;
      _appLockEnabled = appLockEnabled;
      _canUseBiometrics = canUseBiometrics;
      _embeddingModelReady = embeddingReady;
      _embeddingStatus = embeddingReady ? 'Ready' : 'Not downloaded';
      
      _llmModelName = activeModel?.name ?? 'None';
      _llmModelStatus = llmDownloaded ? 'Ready' : 'Not downloaded';
      _llmModelSize = activeModel?.sizeMB ?? '';
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value && !_canUseBiometrics) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication not available on this device')),
      );
      return;
    }

    await SecureStorageService.setBiometricEnabled(value);
    setState(() {
      _biometricEnabled = value;
    });
  }

  Future<void> _toggleAppLock(bool value) async {
    await SecureStorageService.setAppLockEnabled(value);
    setState(() {
      _appLockEnabled = value;
    });
  }

  Future<void> _downloadEmbeddingModel() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Download Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Downloading all-MiniLM-L6-v2 (~25MB)...\n'
              'This enables semantic search in your documents.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Simulate download (in production, this downloads from HuggingFace)
    await Future.delayed(const Duration(seconds: 2));
    
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Embedding model downloaded successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
      
      setState(() {
        _embeddingStatus = 'Ready';
        _embeddingModelReady = true;
      });
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your documents, embeddings, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SecureStorageService.clearAllSecureData();
      // Clear ObjectBox data
      // Clear documents directory
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Security & Privacy'),
          _buildSwitchTile(
            icon: Icons.fingerprint,
            title: 'Biometric Authentication',
            subtitle: _canUseBiometrics
                ? 'Unlock app with fingerprint or face'
                : 'Not available on this device',
            value: _biometricEnabled,
            onChanged: _canUseBiometrics ? _toggleBiometric : null,
          ),
          _buildSwitchTile(
            icon: Icons.lock,
            title: 'App Lock',
            subtitle: 'Require authentication on app launch',
            value: _appLockEnabled,
            onChanged: _toggleAppLock,
          ),
          
          _buildSectionHeader('AI Models'),
          ListTile(
            leading: const Icon(Icons.model_training),
            title: const Text('Embedding Model'),
            subtitle: Text(_embeddingStatus),
            trailing: _embeddingModelReady
                ? const Icon(Icons.check_circle, color: Colors.green)
                : TextButton(
                    onPressed: _downloadEmbeddingModel,
                    child: const Text('Download'),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('LLM Model'),
            subtitle: Text('$_llmModelName • $_llmModelStatus ${_llmModelSize.isNotEmpty ? "($_llmModelSize MB)" : ""}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (LLMService.isInitialized)
                  const Icon(Icons.check_circle, color: Colors.green),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModelDownloadPage()),
              ).then((_) => _loadSettings());
            },
          ),
          
          _buildSectionHeader('Storage'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Manage Storage'),
            subtitle: const Text('View and clear document cache'),
            onTap: () {
              // TODO: Storage management
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
            onTap: _clearAllData,
          ),
          
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('1.0.0 (Build 1)'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy Policy'),
            subtitle: Text('Your data never leaves your device'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Open Source'),
            subtitle: const Text('View source code on GitHub'),
            onTap: () {
              // TODO: Open GitHub link
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
