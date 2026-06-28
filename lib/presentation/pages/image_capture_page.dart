import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/services/ocr_service.dart';
import '../../data/models/objectbox_document.dart';
import '../../data/models/objectbox_note.dart';
import '../../data/objectbox_store.dart';

class ImageCapturePage extends StatefulWidget {
  const ImageCapturePage({super.key});

  @override
  State<ImageCapturePage> createState() => _ImageCapturePageState();
}

class _ImageCapturePageState extends State<ImageCapturePage> {
  final _picker = ImagePicker();
  final List<XFile> _selectedFiles = [];
  bool _isProcessing = false;
  String _processingStatus = '';

  Future<void> _pickFiles() async {
    final files = await _picker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() => _selectedFiles.addAll(files));
    }
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() => _selectedFiles.add(file));
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  Future<void> _processFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Processing 0 of ${_selectedFiles.length}...';
    });

    var processed = 0;

    for (final file in _selectedFiles) {
      setState(() {
        _processingStatus = 'Processing ${processed + 1} of ${_selectedFiles.length}...';
      });

      try {
                final result = await OCRService.processImage(file.path);
                final text = result.text;

        final docDir = Directory(p.dirname(file.path));
        final storedPath = '${docDir.path}/documents/${p.basename(file.path)}';
        await File(file.path).copy(storedPath);

        ObjectBoxStore.insertDocument(ObjectBoxDocument(
          documentId: DateTime.now().millisecondsSinceEpoch.toString(),
          name: p.basename(file.path),
          path: storedPath,
          type: p.extension(file.path).replaceAll('.', ''),
          createdAt: DateTime.now().toIso8601String(),
        ));

        // Auto-create a note from OCR text
        if (text.trim().isNotEmpty) {
          final title = p.basenameWithoutExtension(file.path);
          ObjectBoxStore.insertNote(ObjectBoxNote(
            noteId: DateTime.now().millisecondsSinceEpoch.toString() + '_$processed',
            title: title.length > 100 ? '${title.substring(0, 100)}...' : title,
            content: text.length > 5000 ? '${text.substring(0, 5000)}...' : text,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          ));
        }

        processed++;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing ${p.basename(file.path)}: $e')),
          );
        }
      }
    }

    setState(() {
      _isProcessing = false;
      _selectedFiles.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Processed $processed of ${_selectedFiles.length} files')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Documents'),
        actions: [
          if (_selectedFiles.isNotEmpty && !_isProcessing)
            TextButton(
              onPressed: _processFiles,
              child: const Text('Import'),
            ),
        ],
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_processingStatus),
                ],
              ),
            )
          : _selectedFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Select images or take a photo', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Choose from Gallery'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _selectedFiles.length,
                  itemBuilder: (_, i) {
                    final file = _selectedFiles[i];
                    return Card(
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(file.path),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image),
                          ),
                        ),
                        title: Text(p.basename(file.path), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${(File(file.path).lengthSync() / 1024).toStringAsFixed(0)} KB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _removeFile(i),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _selectedFiles.isNotEmpty && !_isProcessing
          ? FloatingActionButton.extended(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add),
              label: const Text('Add More'),
            )
          : null,
    );
  }
}
