import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/chat/chat_bloc.dart';
import 'presentation/bloc/document/document_bloc.dart';
import 'presentation/pages/onboarding_page.dart';
import 'presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const SmritiApp());
}

class SmritiApp extends StatefulWidget {
  const SmritiApp({super.key});

  @override
  SmritiAppState createState() => SmritiAppState();
}

class SmritiAppState extends State<SmritiApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void setThemeMode(ThemeMode mode) => setState(() => _themeMode = mode);

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('theme_mode') ?? 'system';
    if (mounted) {
      setState(() {
        _themeMode = val == 'light' ? ThemeMode.light : val == 'dark' ? ThemeMode.dark : ThemeMode.system;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.I<DocumentBloc>()),
        BlocProvider(create: (_) => GetIt.I<ChatBloc>()),
      ],
      child: MaterialApp(
        title: 'Smriti',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        home: FutureBuilder<bool>(
          future: _hasSeenOnboarding(),
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) return const SplashPage();
            return snap.data == true ? const SplashPage() : const OnboardingPage();
          },
        ),
      ),
    );
  }

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }
}
