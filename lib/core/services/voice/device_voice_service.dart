import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'voice_service.dart';

/// Real on-device speech-to-text via the `speech_to_text` plugin (Android, iOS,
/// web/Chrome, macOS). Permission is requested on first [available] call; if
/// the platform has no recogniser, [available] returns false and the UI falls
/// back to typing.
class DeviceVoiceService implements VoiceService {
  final SpeechToText _stt = SpeechToText();
  bool _initialised = false;
  bool _available = false;
  void Function()? _onDone;

  @override
  bool get isListening => _stt.isListening;

  @override
  Future<bool> available() async {
    if (_initialised) return _available;
    _initialised = true;
    try {
      _available = await _stt.initialize(
        onError: (_) => _finish(),
        onStatus: (String status) {
          if (status == 'done' || status == 'notListening') _finish();
        },
      );
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  @override
  Future<void> listen({
    required void Function(VoiceResult result) onResult,
    void Function()? onDone,
  }) async {
    if (!await available()) {
      onDone?.call();
      return;
    }
    _onDone = onDone;
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) {
        onResult(VoiceResult(r.recognizedWords, isFinal: r.finalResult));
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (_stt.isListening) await _stt.stop();
    _finish();
  }

  void _finish() {
    final void Function()? cb = _onDone;
    _onDone = null;
    cb?.call();
  }
}
