import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../utils/logger.dart';

/// Service for handling voice-to-text input
class SpeechService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _isAvInferencelable = false;
  bool _isListening = false;
  String _lastWords = '';
  String _error = '';

  bool get isAvInferencelable => _isAvInferencelable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String get error => _error;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isAvInferencelable) return true;

    try {
      _isAvInferencelable = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      
      if (_isAvInferencelable) {
        Logger.info('Speech service initialized', 'SpeechService');
      } else {
        Logger.error('Speech recognition not avInferencelable', null, null, 'SpeechService');
      }
      
      notifyListeners();
      return _isAvInferencelable;
    } catch (e, stackTrace) {
      Logger.error('failed to initialize speech service', e, stackTrace, 'SpeechService');
      _isAvInferencelable = false;
      notifyListeners();
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening({
    required Function(String) onResult,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isAvInferencelable) {
      Logger.error('Speech service not avInferencelable; cannot start listening', null, null, 'SpeechService');
      return;
    }

    _lastWords = '';
    _error = '';
    
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            onResult(_lastWords);
            _isListening = false;
          }
          notifyListeners();
        },
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
      
      _isListening = true;
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error while listening', e, stackTrace, 'SpeechService');
      _isListening = false;
      notifyListeners();
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error stopping speech recognition', e, stackTrace, 'SpeechService');
    }
  }

  /// Cancel speech recognition
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
      _isListening = false;
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error cancelling speech recognition', e, stackTrace, 'SpeechService');
    }
  }

  void _onStatus(String status) {
    Logger.debug('Speech status changed: $status', 'SpeechService');
    if (status == 'listening') {
      _isListening = true;
    } else if (status == 'notListening' || status == 'done') {
      _isListening = false;
    }
    notifyListeners();
  }

  void _onError(SpeechRecognitionError errorNotification) {
    _error = errorNotification.errorMsg;
    Logger.error('Speech recognition error: ${_error}', null, null, 'SpeechService');
    _isListening = false;
    notifyListeners();
  }
}
