import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderPage extends StatefulWidget {
  const AudioRecorderPage({super.key});

  @override
  State<AudioRecorderPage> createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends State<AudioRecorderPage> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordingPath;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _snack('Microphone permission denied');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/recordings/${DateTime.now().millisecondsSinceEpoch}.m4a';
    await File(path).parent.create(recursive: true);

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordingPath = path;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (path != null) {
    setState(() {
      _isRecording = false;
      _hasRecording = true;
      _recordingPath = path;
    });
    _snack('Recording saved');
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;
    // Playback handled by the record package's AudioPlayer or system player
    _snack('Audio saved at: $_recordingPath');
  }

  Future<void> _deleteRecording() async {
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) await file.delete();
    }
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
    });
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Recorder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 80,
              color: _isRecording ? Colors.red : colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              _isRecording
                  ? 'Recording...'
                  : _hasRecording
                      ? 'Recording saved'
                      : 'Tap to record',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            FloatingActionButton.large(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              backgroundColor: _isRecording ? Colors.red : colorScheme.primary,
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: 36,
              ),
            ),
            if (_hasRecording) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _playRecording,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _deleteRecording,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
