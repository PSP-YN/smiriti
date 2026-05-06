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

  Future<void> _pickDocument() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Document',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_open, color: Colors.blue),
                ),
                title: const Text('Choose File'),
                subtitle: const Text('PDF, TXT, Images, Audio'),
                onTap: () => Navigator.pop(context, 'files'),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Capture and extract text via OCR'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    if (source == 'files') {
      await _pickFile();
    } else if (source == 'camera') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ImageCapturePage()),
      );
    }
  }

  Future<void> _pickFile() async {
    // Android 12 and below need explicit READ_EXTERNAL_STORAGE permission
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        if (!result.isGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to pick files.'),
              action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
            ),
          );
          return;
        }
      }
    }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file picker: ${e.toString().split('\n').first}'),
            action: const SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
          const Text(
            AppConstants.appName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
            Text(
              AppConstants.appTagline,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(150),
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
              // Reload documents in case data was cleared
              context.read<DocumentBloc>().add(const LoadDocuments());
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
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state is DocumentProcessed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ "${state.document.name}" processed and indexed'),
                backgroundColor: Colors.green,
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
                      context
                          .read<DocumentBloc>()
                          .add(DeleteDocument(doc.id));
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
