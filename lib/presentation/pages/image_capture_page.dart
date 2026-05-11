import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/document/document_bloc.dart';

class ImageCapturePage extends StatefulWidget {
  const ImageCapturePage({super.key});

  @override
  State<ImageCapturePage> createState() => _ImageCapturePageState();
}

class _ImageCapturePageState extends State<ImageCapturePage> {
  final _picker = ImagePicker();
  bool _isProcessing = false;
  String _status = '';

  // ── Camera capture ────────────────────────────────────────────────────────

  Future<void> _captureFromCamera() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      if (mounted) _showPermissionDenied('Camera');
      return;
    }

    _setProcessing(true, 'Opening camera...');

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (photo == null) {
        _setProcessing(false);
        return;
      }
      await _processImageFile(photo.path, photo.name);
    } catch (e) {
      _handleError(e);
    }
  }

  // ── Gallery picker ────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    _setProcessing(true, 'Opening gallery...');
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (photo == null) {
        _setProcessing(false);
        return;
      }
      await _processImageFile(photo.path, photo.name);
    } catch (e) {
      _handleError(e);
    }
  }

  // ── File picker (PDF, TXT, Audio, Video) ──────────────────────────────────

  Future<void> _pickDocument() async {
    _setProcessing(true, 'Opening file browser...');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf', 'txt',
          'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac',
          'mp4', 'mov', 'avi', 'mkv',
        ],
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) {
        _setProcessing(false);
        return;
      }
      final path = result.files.single.path;
      if (path == null) {
        _setProcessing(false);
        return;
      }
      _setProcessing(true, 'Processing document...');
      if (mounted) {
        context.read<DocumentBloc>().add(AddDocument(File(path)));
        _showSuccess('Processing document…');
        Navigator.pop(context);
      }
    } catch (e) {
      _handleError(e);
    }
  }

  // ── Shared file processing ────────────────────────────────────────────────

  Future<void> _processImageFile(String sourcePath, String name) async {
    _setProcessing(true, 'Saving image...');

    final appDir = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${appDir.path}/documents');
    if (!await docsDir.exists()) await docsDir.create(recursive: true);

    final id = DateTime.now().millisecondsSinceEpoch;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
    final destPath = '${docsDir.path}/${id}_capture.$ext';
    await File(sourcePath).copy(destPath);

    if (mounted) {
      context.read<DocumentBloc>().add(AddDocument(File(destPath)));
      _showSuccess('Image captured — extracting text via OCR…');
      Navigator.pop(context);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setProcessing(bool value, [String status = '']) {
    if (mounted) setState(() { _isProcessing = value; _status = status; });
  }

  void _handleError(Object e) {
    _setProcessing(false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().split('\n').first}')),
      );
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _showPermissionDenied(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type permission is required.'),
        action: const SnackBarAction(label: 'Settings', onPressed: openAppSettings),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Document'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Icon
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.document_scanner_rounded,
                  size: 52,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Add a Document',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture, pick an image, or browse for files.\nText is extracted automatically.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // ── Action buttons ───────────────────────────────────────────────

            if (_isProcessing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ] else ...[
              _ActionButton(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                subtitle: 'Extract text via OCR',
                color: const Color(0xFF059669),
                onPressed: _captureFromCamera,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                subtitle: 'Pick any image',
                color: const Color(0xFF0284C7),
                onPressed: _pickFromGallery,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.folder_open_rounded,
                label: 'Browse Files',
                subtitle: 'PDF, Audio, Video & more',
                color: const Color(0xFF4F46E5),
                onPressed: _pickDocument,
              ),
            ],

            const SizedBox(height: 28),

            // ── Tips ─────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(50),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withAlpha(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates_rounded,
                          size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for best OCR results',
                        style: textTheme.labelLarge
                            ?.copyWith(color: colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '• Use even, bright lighting\n'
                    '• Keep the document flat and still\n'
                    '• Avoid shadows and glare\n'
                    '• Ensure all text is within the frame\n'
                    '• Higher resolution = better accuracy',
                    style: TextStyle(fontSize: 13, height: 1.65),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Action button widget ──────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withAlpha(80), width: 1.5),
            borderRadius: BorderRadius.circular(16),
            color: color.withAlpha(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(140))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: color.withAlpha(180)),
            ],
          ),
        ),
      ),
    );
  }
}
