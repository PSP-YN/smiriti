import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/document_local_datasource.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../domain/repositories/document_repository.dart';
import '../../presentation/bloc/document/document_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // External services - minimal initialization
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Data sources
  getIt.registerLazySingleton<DocumentLocalDataSource>(
    () => DocumentLocalDataSourceImpl(prefs),
  );

  // Repositories
  getIt.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(getIt()),
  );

  // BLoCs
  getIt.registerFactory<DocumentBloc>(
    () => DocumentBloc(getIt()),
  );
}
