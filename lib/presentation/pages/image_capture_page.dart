import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/services/ocr_service.dart';
import '../../data/datasources/document_local_datasource.dart';
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
  final List<PlatformFile> _selectedFiles = [];
  bool _isProcessing = false;
  String _processingStatus = '';

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(files.map((f) => PlatformFile(
          name: f.name,
          path: f.path,
          size: 0,
        )));
      });
    }
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() {
        _selectedFiles.add(PlatformFile(
          name: file.name,
          path: file.path,
          size: 0,
        ));
      });
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md', 'doc', 'docx'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFiles.addAll(result.files));
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  String _fileIcon(PlatformFile file) {
    final ext = p.extension(file.name).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) return 'image';
    if (ext == '.pdf') return 'pdf';
    if (['.txt', '.md'].contains(ext)) return 'text';
    if (['.doc', '.docx'].contains(ext)) return 'doc';
    return 'file';
  }

  Future<void> _processFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Processing 0 of ${_selectedFiles.length}...';
    });

    var processed = 0;
    final datasource = DocumentLocalDataSourceImpl();

    for (final file in _selectedFiles) {
      setState(() {
        _processingStatus = 'Processing ${processed + 1} of ${_selectedFiles.length}...';
      });

      try {
        final filePath = file.path;
        if (filePath == null) continue;

        final ext = p.extension(filePath).toLowerCase();
        String text;

        if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
          final result = await OCRService.processImage(filePath);
          text = result.text;
        } else if (ext == '.pdf') {
          final extracted = await datasource.saveDocument(File(filePath));
          text = extracted.extractedText.join('\n');
        } else {
          text = await File(filePath).readAsString();
        }

        final docDir = Directory(p.dirname(filePath));
        final storedPath = '${docDir.path}/documents/${p.basename(filePath)}';
        await File(filePath).copy(storedPath);

        ObjectBoxStore.insertDocument(ObjectBoxDocument(
          documentId: DateTime.now().millisecondsSinceEpoch.toString(),
          name: p.basename(filePath),
          path: storedPath,
          type: ext.replaceAll('.', ''),
          createdAt: DateTime.now().toIso8601String(),
        ));

        if (text.trim().isNotEmpty) {
          final title = p.basenameWithoutExtension(filePath);
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
            SnackBar(content: Text('Error processing ${file.name}: $e')),
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
        SnackBar(content: Text('Processed $processed files')),
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
                      const Icon(Icons.upload_file, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Import images, PDFs, or documents', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Images from Gallery'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickDocuments,
                        icon: const Icon(Icons.description),
                        label: const Text('PDF / Documents'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _selectedFiles.length,
                  itemBuilder: (_, i) {
                    final file = _selectedFiles[i];
                    final iconType = _fileIcon(file);
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          iconType == 'image' ? Icons.image : iconType == 'pdf' ? Icons.picture_as_pdf : Icons.description,
                          size: 32,
                        ),
                        title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
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
              onPressed: _pickImages,
              icon: const Icon(Icons.add),
              label: const Text('Add More'),
            )
          : null,
    );
  }
}
