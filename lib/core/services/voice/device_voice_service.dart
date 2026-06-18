import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'voice_service.dart';

/// On-device speech recognition for Android and iOS via [speech_to_text].
class DeviceVoiceService implements VoiceService {
  DeviceVoiceService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _listening = false;
  bool _initialized = false;
  void Function(String message)? _onError;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;
    _initialized = await _speech.initialize(
      onError: (dynamic error) {
        if (_listening) {
          _onError?.call(error.errorMsg);
        }
      },
      onStatus: (String status) {
        if (status == 'done' || status == 'notListening') {
          _listening = false;
        }
      },
    );
    return _initialized && _speech.isAvailable;
  }

  @override
  Future<bool> isAvailable() async {
    if (!_initialized) {
      await initialize();
    }
    return _speech.isAvailable;
  }

  @override
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(String message) onError,
  }) async {
    if (_listening) return;
    _onError = onError;

    final bool ready = await initialize();
    if (!ready) {
      onError('Speech recognition is not available on this device.');
      return;
    }
    final bool permitted = await _speech.hasPermission;
    if (!permitted) {
      onError('Microphone permission denied. Enable it in Settings to use voice capture.');
      return;
    }

    _listening = true;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) {
          _listening = false;
        }
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  @override
  Future<void> stopListening() async {
    if (!_listening) return;
    await _speech.stop();
    _listening = false;
  }

  @override
  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
    _listening = false;
  }
}
