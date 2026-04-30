import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    context.read<DocumentBloc>().add(const LoadDocuments());
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> _pickDocument() async {
    // Show options for document types
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Files'),
              subtitle: const Text('PDF, TXT, Images, Audio'),
              onTap: () => Navigator.pop(context, 'files'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              subtitle: const Text('Take a photo to OCR'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
          ],
        ),
      ),
    );

    if (source == 'files') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (context.mounted) {
          context.read<DocumentBloc>().add(AddDocument(file));
        }
      }
    } else if (source == 'camera') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ImageCapturePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              AppConstants.appName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              AppConstants.appTagline,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: 'Summarize',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SummarizePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<DocumentBloc, DocumentState>(
        listener: (context, state) {
          if (state is DocumentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is DocumentLoading) {
            return const LoadingIndicator(message: 'Loading documents...');
          }

          if (state is DocumentProcessing) {
            return LoadingIndicator(message: state.message);
          }

          if (state is DocumentsLoaded) {
            if (state.documents.isEmpty) {
              return EmptyState(
                onAddDocument: _pickDocument,
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: state.documents.length,
                itemBuilder: (context, index) {
                  final doc = state.documents[index];
                  return DocumentCard(
                    document: doc,
                    onDelete: () {
                      context.read<DocumentBloc>().add(
                        DeleteDocument(doc.id),
                      );
                    },
                  );
                },
              ),
            );
          }

          return EmptyState(onAddDocument: _pickDocument);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickDocument,
        icon: const Icon(Icons.add),
        label: const Text('Add Document'),
      ),
    );
  }
}
