import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/di/injection.dart';
import 'core/error/error_handler.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/document/document_bloc.dart';
import 'presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const SmritiApp());
}

class SmritiApp extends StatelessWidget {
  const SmritiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => GetIt.I<DocumentBloc>(),
          ),
        ],
        child: MaterialApp(
          title: 'Smriti',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: const SplashPage(),
        ),
      ),
    );
  }
}
