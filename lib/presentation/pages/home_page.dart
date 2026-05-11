import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../bloc/document/document_bloc.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'chat_page.dart';
import 'image_capture_page.dart';
import 'settings_page.dart';
import 'summarize_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<DocumentBloc>().add(const LoadDocuments());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Source picker bottom sheet ────────────────────────────────────────────

  Future<void> _pickDocument() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddDocumentSheet(),
    );

    if (source == null || !mounted) return;

    switch (source) {
      case 'files':
        await _pickFile();
      case 'camera':
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ImageCapturePage()),
          );
        }
      case 'gallery':
        await _pickFromGallery();
      case 'video':
        await _pickVideo();
    }
  }

  // ── File picker (documents + all supported types) ─────────────────────────

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedExtensions,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      if (mounted) {
        context.read<DocumentBloc>().add(AddDocument(File(path)));
      }
    } catch (e) {
      if (mounted) {
        _showError('Could not open file picker: ${e.toString().split('\n').first}');
      }
    }
  }

  // ── Gallery photo picker ──────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    // Android 13+ uses READ_MEDIA_IMAGES; older uses READ_EXTERNAL_STORAGE
    if (Platform.isAndroid) {
      final sdk = await _getAndroidSdk();
      if (sdk >= 33) {
        final status = await Permission.photos.request();
        if (!status.isGranted && mounted) {
          _showPermissionDenied('Photos');
          return;
        }
      }
      // Below 33: file_picker / image_picker handles it internally
    }

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (photo == null) return;

      if (mounted) {
        context.read<DocumentBloc>().add(AddDocument(File(photo.path)));
      }
    } catch (e) {
      if (mounted) _showError('Could not open gallery: ${e.toString().split('\n').first}');
    }
  }

  // ── Video picker ─────────────────────────────────────────────────────────

  Future<void> _pickVideo() async {
    if (Platform.isAndroid) {
      final sdk = await _getAndroidSdk();
      if (sdk >= 33) {
        final status = await Permission.videos.request();
        if (!status.isGranted && mounted) {
          _showPermissionDenied('Videos');
          return;
        }
      }
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      if (mounted) {
        context.read<DocumentBloc>().add(AddDocument(File(path)));
      }
    } catch (e) {
      if (mounted) _showError('Could not open video picker: ${e.toString().split('\n').first}');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: const SnackBarAction(label: 'Settings', onPressed: openAppSettings),
      ),
    );
  }

  void _showPermissionDenied(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type permission is required.'),
        action: const SnackBarAction(label: 'Open Settings', onPressed: openAppSettings),
      ),
    );
  }

  /// Best-effort way to detect Android API level from the OS version string.
  Future<int> _getAndroidSdk() async {
    try {
      final version = Platform.operatingSystemVersion;
      // The OS version string on Android looks like "Linux 5.x.x ..."
      // We can't get exact SDK from Dart directly without a plugin,
      // so we assume 33+ if it's not obviously old. Return safe default.
      if (version.contains('Android')) return 33;
      return 33; // assume modern
    } catch (_) {
      return 33;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              AppConstants.appName,
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              AppConstants.appTagline,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withAlpha(180),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Summarize',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SummarizePage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'AI Chat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ).then((_) {
              if (mounted) {
                context.read<DocumentBloc>().add(const LoadDocuments());
              }
            }),
          ),
        ],
      ),
      body: BlocConsumer<DocumentBloc, DocumentState>(
        listener: (context, state) {
          if (state is DocumentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          } else if (state is DocumentProcessed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ "${state.document.name}" processed and indexed'),
                backgroundColor: Colors.green.shade600,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DocumentLoading) {
            return const LoadingIndicator(message: 'Loading documents...');
          }

          if (state is DocumentProcessing) {
            return LoadingIndicator(
              message: state.message,
              documentName: state.document.name,
            );
          }

          final docs = state is DocumentsLoaded ? state.documents : <dynamic>[];

          if (docs.isEmpty) {
            return EmptyState(onAddDocument: _pickDocument);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DocumentBloc>().add(const LoadDocuments());
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return DocumentCard(
                    document: doc,
                    onDelete: () {
                      context.read<DocumentBloc>().add(DeleteDocument(doc.id));
                    },
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(initialDocumentId: doc.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_doc_fab',
        onPressed: _pickDocument,
        icon: const Icon(Icons.add),
        label: const Text('Add Document'),
      ),
    );
  }
}

// ── Add Document bottom sheet widget ────────────────────────────────────────

class _AddDocumentSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add Document',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),

            const _SheetTile(
              icon: Icons.folder_open_rounded,
              iconColor: Color(0xFF4F46E5),
              title: 'Browse Files',
              subtitle: 'PDF, TXT and more',
              value: 'files',
            ),
            const _SheetTile(
              icon: Icons.camera_alt_rounded,
              iconColor: Color(0xFF059669),
              title: 'Take Photo',
              subtitle: 'Capture & extract text via OCR',
              value: 'camera',
            ),
            const _SheetTile(
              icon: Icons.photo_library_rounded,
              iconColor: Color(0xFF0284C7),
              title: 'Choose Photo',
              subtitle: 'Pick image from gallery',
              value: 'gallery',
            ),
            const _SheetTile(
              icon: Icons.video_library_rounded,
              iconColor: Color(0xFFDB2777),
              title: 'Choose Video',
              subtitle: 'MP4, MOV, AVI and more',
              value: 'video',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;

  const _SheetTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => Navigator.pop(context, value),
    );
  }
}
