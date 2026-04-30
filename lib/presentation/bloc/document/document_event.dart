part of 'document_bloc.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocuments extends DocumentEvent {
  const LoadDocuments();
}

class AddDocument extends DocumentEvent {
  final File file;

  const AddDocument(this.file);

  @override
  List<Object?> get props => [file];
}

class DeleteDocument extends DocumentEvent {
  final String documentId;

  const DeleteDocument(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

class ProcessDocument extends DocumentEvent {
  final String documentId;

  const ProcessDocument(this.documentId);

  @override
  List<Object?> get props => [documentId];
}
