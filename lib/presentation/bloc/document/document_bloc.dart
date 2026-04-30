import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/document.dart';
import '../../../domain/repositories/document_repository.dart';

part 'document_event.dart';
part 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final DocumentRepository _repository;

  DocumentBloc(this._repository) : super(DocumentInitial()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<AddDocument>(_onAddDocument);
    on<DeleteDocument>(_onDeleteDocument);
    on<ProcessDocument>(_onProcessDocument);
  }

  Future<void> _onLoadDocuments(
    LoadDocuments event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());
    try {
      final documents = await _repository.getAllDocuments();
      emit(DocumentsLoaded(documents));
    } catch (e) {
      emit(DocumentError('Failed to load documents: $e'));
    }
  }

  Future<void> _onAddDocument(
    AddDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());
    try {
      final document = await _repository.addDocument(event.file);
      
      final currentState = state;
      if (currentState is DocumentsLoaded) {
        final updatedDocs = [...currentState.documents, document];
        emit(DocumentsLoaded(updatedDocs));
      } else {
        final allDocs = await _repository.getAllDocuments();
        emit(DocumentsLoaded(allDocs));
      }
      
      add(ProcessDocument(document.id));
    } catch (e) {
      emit(DocumentError('Failed to add document: $e'));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocument event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());
    try {
      await _repository.deleteDocument(event.documentId);
      final documents = await _repository.getAllDocuments();
      emit(DocumentsLoaded(documents));
    } catch (e) {
      emit(DocumentError('Failed to delete document: $e'));
    }
  }

  Future<void> _onProcessDocument(
    ProcessDocument event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      final document = await _repository.getDocumentById(event.documentId);
      if (document == null) return;

      emit(DocumentProcessing(document, 'Extracting text...'));
      
      final extractedText = await _repository.extractTextFromDocument(document);
      
      emit(DocumentProcessing(document, 'Chunking document...'));
      
      await _repository.chunkDocument(
        document.copyWith(extractedText: extractedText),
        extractedText,
      );

      emit(DocumentProcessed(document));
      
      final documents = await _repository.getAllDocuments();
      emit(DocumentsLoaded(documents));
    } catch (e) {
      emit(DocumentError('Failed to process document: $e'));
    }
  }
}
