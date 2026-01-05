import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Service for handling voice search functionality
class VoiceSearchService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String? _lastError;

  /// Check if microphone permission is granted
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Check if voice search is available
  Future<bool> isAvailable() async {
    try {
      // First check permission
      final hasPermission = await checkMicrophonePermission();
      if (!hasPermission) {
        AppLogger.warning('🎤 Microphone permission not granted');
        _lastError = 'Microphone permission denied';
        return false;
      }

      if (!_isInitialized) {
        _isInitialized = await _speechToText.initialize(
          onError: (error) {
            _lastError = error.errorMsg;
            AppLogger.error('🎤 Speech recognition error: ${error.errorMsg}');
          },
          onStatus: (status) {
            AppLogger.debug('🎤 Speech recognition status: $status');
          },
        );
      }

      if (!_isInitialized) {
        _lastError = 'Speech recognition not available on this device';
      }

      return _isInitialized;
    } catch (e) {
      AppLogger.error('🎤 Error initializing speech recognition', error: e);
      _lastError = e.toString();
      return false;
    }
  }

  /// Get last error message
  String? get lastError => _lastError;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Start listening for voice input
  Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback onError,
  }) async {
    if (!await isAvailable()) {
      AppLogger.warning('🎤 Speech recognition not available');
      onError();
      return;
    }

    if (_isListening) {
      AppLogger.warning('🎤 Already listening');
      return;
    }

    _isListening = true;
    AppLogger.info('🎤 Started listening for voice input');

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          AppLogger.info('🎤 Voice result: ${result.recognizedWords}');
          onResult(result.recognizedWords);
          stopListening();
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: false,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      AppLogger.info('🎤 Stopped listening');
    }
  }

  /// Cancel listening
  Future<void> cancel() async {
    if (_isListening) {
      await _speechToText.cancel();
      _isListening = false;
      AppLogger.info('🎤 Cancelled listening');
    }
  }

  /// Dispose resources
  void dispose() {
    _speechToText.stop();
  }
}
