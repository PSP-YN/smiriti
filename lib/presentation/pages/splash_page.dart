import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_initializer.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _progress = 0.0;
  String _status = 'Initializing...';
  bool _hasError = false;
  List<Map<String, dynamic>> _failedSteps = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Listen to progress updates
    AppInitializer.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          _updateStatus(progress);
        });
      }
    });

    // Initialize
    final success = await AppInitializer.initialize();
    
    if (!success) {
      final report = AppInitializer.getInitReport();
      setState(() {
        _hasError = true;
        _failedSteps = List<Map<String, dynamic>>.from(report['failedSteps']);
      });
      
      // Wait a moment to show the error state
      await Future.delayed(const Duration(seconds: 2));
    }

    // Navigate to home regardless (app works in degraded mode)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  void _updateStatus(double progress) {
    if (progress < 0.2) {
      _status = 'Loading storage...';
    } else if (progress < 0.4) {
      _status = 'Initializing security...';
    } else if (progress < 0.6) {
      _status = 'Setting up database...';
    } else if (progress < 0.8) {
      _status = 'Loading AI models...';
    } else {
      _status = 'Almost ready...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              AnimatedLogo(
                size: 120,
                animate: !_hasError,
              ),
              const SizedBox(height: 32),
              
              // App name
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.appTagline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(height: 48),
              
              // Progress indicator
              if (!_hasError) ...[
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _status,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              
              // Error state
              if (_hasError) ...[
                Icon(
                  Icons.warning_amber,
                  size: 48,
                  color: Colors.orange.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Some features may be limited',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_failedSteps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_failedSteps.length} component(s) failed to load',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ),
              ],
              
              const SizedBox(height: 48),
              
              // Features preview with staggered animation
              FadeAnimation(
                delay: const Duration(milliseconds: 500),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildFeatureChip(Icons.document_scanner, 'PDF'),
                    _buildFeatureChip(Icons.image, 'OCR'),
                    _buildFeatureChip(Icons.audiotrack, 'Audio'),
                    _buildFeatureChip(Icons.chat, 'Chat'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
    );
  }
}
