import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_initializer.dart';
import '../../core/services/secure_storage_service.dart';
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
  bool _needsAuth = false;
  bool _authFailed = false;

  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  bool _needsPinAuth = false;
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _progressSub?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    _progressSub = AppInitializer.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          _updateStatus(progress);
        });
      }
    });

    final success = await AppInitializer.initialize();

    if (!success) {
      final report = AppInitializer.getInitReport();
      if (mounted) {
        setState(() {
          _hasError = true;
          _failedSteps = List<Map<String, dynamic>>.from(report['failedSteps']);
        });
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    final appLockEnabled = await SecureStorageService.isAppLockEnabled();
    final hasPin = await SecureStorageService.hasAppPin();

    if (appLockEnabled && mounted) {
      setState(() => _needsAuth = true);
      final authed = await SecureStorageService.authenticateWithBiometrics(
        reason: 'Authenticate to unlock Smriti',
      );
      if (authed && mounted) { _navigateHome(); return; }
      if (hasPin && mounted) {
        setState(() => _needsPinAuth = true);
        return;
      }
      if (!hasPin && mounted) await _runBiometricAuth();
    } else if (hasPin && mounted) {
      setState(() => _needsPinAuth = true);
    } else {
      _navigateHome();
    }
  }

  void _verifyPin() {
    SecureStorageService.verifyAppPin(_pinController.text).then((valid) {
      if (valid && mounted) {
        _navigateHome();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PIN')),
        );
      }
    });
  }

  Future<void> _runBiometricAuth() async {
    final authenticated = await SecureStorageService.authenticateWithBiometrics(
      reason: 'Authenticate to unlock Smriti',
    );

    if (!mounted) return;

    if (authenticated) {
      _navigateHome();
    } else {
      setState(() => _authFailed = true);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) await _runBiometricAuth();
    }
  }

  void _navigateHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  void _updateStatus(double progress) {
    if (progress < 0.17) {
      _status = 'Loading storage...';
    } else if (progress < 0.33) {
      _status = 'Initializing security...';
    } else if (progress < 0.5) {
      _status = 'Setting up database...';
    } else if (progress < 0.67) {
      _status = 'Starting OCR engine...';
    } else if (progress < 0.84) {
      _status = 'Loading AI models...';
    } else {
      _status = 'Almost ready...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                AnimatedLogo(size: 120, animate: !_hasError && !_needsAuth),
                const SizedBox(height: 32),

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
                        color: colorScheme.onSurface.withAlpha(150),
                      ),
                ),

                const SizedBox(height: 48),

                if (_needsPinAuth) ...[
                  const Icon(Icons.pin, size: 64),
                  const SizedBox(height: 16),
                  const Text('Enter PIN to unlock'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _pinController,
                      decoration: const InputDecoration(
                        labelText: 'PIN',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      onSubmitted: (_) => _verifyPin(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _verifyPin, child: const Text('Unlock')),
                ] else if (_needsAuth) ...[
                  Icon(
                    Icons.fingerprint,
                    size: 64,
                    color: _authFailed ? Colors.red : colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _authFailed
                        ? 'Authentication failed. Retrying...'
                        : 'Tap to authenticate',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _authFailed ? Colors.red : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _runBiometricAuth,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Retry Authentication'),
                  ),
                ] else if (!_hasError) ...[
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: colorScheme.primary.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 16),
                  Text(_status, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ] else ...[
                  Icon(Icons.warning_amber, size: 48, color: Colors.orange.shade400),
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
                        '${_failedSteps.length} component(s) failed to initialize',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
                      ),
                    ),
                ],

                const Spacer(),

                FadeAnimation(
                  delay: const Duration(milliseconds: 300),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _featureChip(Icons.picture_as_pdf, 'PDF'),
                      _featureChip(Icons.image_search, 'OCR'),
                      _featureChip(Icons.mic, 'Audio'),
                      _featureChip(Icons.chat_bubble_outline, 'AI Chat'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor:
          Theme.of(context).colorScheme.primaryContainer.withAlpha(60),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }
}
