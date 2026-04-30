part of 'document_bloc.dart';

abstract class DocumentState extends Equatable {
  const DocumentState();

  @override
  List<Object?> get props => [];
}

class DocumentInitial extends DocumentState {}

class DocumentLoading extends DocumentState {}

class DocumentsLoaded extends DocumentState {
  final List<Document> documents;

  const DocumentsLoaded(this.documents);

  @override
  List<Object?> get props => [documents];
}

class DocumentProcessing extends DocumentState {
  final Document document;
  final String message;

  const DocumentProcessing(this.document, this.message);

  @override
  List<Object?> get props => [document, message];
}

class DocumentProcessed extends DocumentState {
  final Document document;

  const DocumentProcessed(this.document);

  @override
  List<Object?> get props => [document];
}

class DocumentError extends DocumentState {
  final String message;

  const DocumentError(this.message);

  @override
  List<Object?> get props => [message];
}
