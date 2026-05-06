import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.privacy_tip,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Smriti Privacy Policy',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last updated: ${AppConstants.privacyPolicyDate}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(130),
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          _section(
            context,
            icon: Icons.offline_bolt,
            title: '100% Offline — Your Data Never Leaves Your Device',
            body:
                'Smriti is a completely offline application. All processing — including document parsing, OCR, text embedding, and AI inference — happens entirely on your device using on-device models.\n\n'
                'We do not collect, transmit, store, or share any of your personal data, documents, or usage information with any server, third party, or cloud service.',
          ),

          _section(
            context,
            icon: Icons.folder_off,
            title: 'What Data We Store',
            body:
                'All data is stored exclusively on your device in the app\'s private storage directory. This includes:\n\n'
                '• Documents you import (PDF, images, audio)\n'
                '• Extracted text and semantic embeddings\n'
                '• AI model files you choose to download\n'
                '• App settings and preferences\n\n'
                'You can delete all data at any time from Settings → Clear All Data.',
          ),

          _section(
            context,
            icon: Icons.lock,
            title: 'Security',
            body:
                'Smriti uses Android\'s EncryptedSharedPreferences and AES-GCM encryption to protect sensitive settings. '
                'Optional biometric authentication (fingerprint / face unlock) can be enabled in Settings to restrict access to the app.\n\n'
                'No network connections are made by the core app. Model downloads (when you choose to download AI models) connect only to Hugging Face Hub using HTTPS.',
          ),

          _section(
            context,
            icon: Icons.download,
            title: 'Model Downloads',
            body:
                'When you choose to download AI models (e.g., Gemma 2B, Llama 3.2 1B, all-MiniLM-L6-v2), the app connects to Hugging Face\'s servers via HTTPS to download those model files. '
                'No personal data is sent in this request — only a standard HTTP file download.\n\n'
                'Downloaded models are stored locally on your device and are never uploaded anywhere.',
          ),

          _section(
            context,
            icon: Icons.camera_alt,
            title: 'Permissions',
            body:
                'Smriti requests the following Android permissions:\n\n'
                '• Camera — to capture document photos for OCR\n'
                '• Storage (READ) — to open documents from your files\n'
                '• Internet — only for model downloads (optional)\n'
                '• Biometric — to enable fingerprint/face unlock (optional)\n\n'
                'All permissions are requested only when needed and can be revoked in your device settings.',
          ),

          _section(
            context,
            icon: Icons.child_care,
            title: 'Children\'s Privacy',
            body:
                'Smriti does not collect any personal information and does not have age restrictions. Since all data stays on-device, there are no child-data concerns under COPPA or GDPR.',
          ),

          _section(
            context,
            icon: Icons.update,
            title: 'Changes to This Policy',
            body:
                'If we update this privacy policy, the new version will be included with the app update and will note the new "Last updated" date above.',
          ),

          _section(
            context,
            icon: Icons.mail_outline,
            title: 'Contact',
            body:
                'Questions about privacy? This app was built as part of a college project.\n\n'
                'App: ${AppConstants.appName} v${AppConstants.appVersion}',
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(60),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user,
                    color: colorScheme.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'TL;DR — Everything stays on your phone. We see nothing.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }
}
