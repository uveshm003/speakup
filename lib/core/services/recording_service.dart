import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Thin wrapper around the `record` package.
///
/// Usage:
/// ```dart
/// final service = RecordingService();
/// final ok = await service.startRecording('session_id_123');
/// // ... time passes ...
/// final path = await service.stopRecording(); // null if not recording
/// ```
class RecordingService {
  RecordingService() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;

  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  /// Requests permission and starts recording to a file named [sessionId].m4a
  /// inside the app's documents directory.
  ///
  /// Returns `true` if recording started successfully, `false` if permission
  /// was denied or an error occurred.
  Future<bool> startRecording(String sessionId) async {
    try {
      final bool hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        return false;
      }

      final Directory dir = await getApplicationDocumentsDirectory();
      final String recordingsDir = '${dir.path}/recordings';
      await Directory(recordingsDir).create(recursive: true);

      _currentPath = '$recordingsDir/$sessionId.m4a';

      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100), path: _currentPath!);

      _isRecording = true;
      return true;
    } catch (_) {
      _isRecording = false;
      _currentPath = null;
      return false;
    }
  }

  /// Stops the current recording and returns the absolute path of the saved
  /// file, or `null` if nothing was being recorded.
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      return null;
    }
    try {
      await _recorder.stop();
      final String? path = _currentPath;
      _isRecording = false;
      _currentPath = null;
      return path;
    } catch (_) {
      _isRecording = false;
      _currentPath = null;
      return null;
    }
  }

  /// Cancels the current recording without saving.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    try {
      await _recorder.cancel();
    } catch (_) {}
    _isRecording = false;
    _currentPath = null;
  }

  /// Deletes a previously saved recording file.
  static Future<void> deleteRecordingFile(String path) async {
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
