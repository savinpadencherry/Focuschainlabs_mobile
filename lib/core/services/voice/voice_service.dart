import 'package:speech_to_text/speech_to_text.dart';

/// On-device speech-to-text.
///
/// Dictation is the point of the lead chat: a rep walking out of a site visit
/// will speak a note and will not type one, so a note that takes thirty
/// seconds of typing is a note that never gets logged.
///
/// Recognition happens on the device via the platform recogniser. Nothing is
/// uploaded to transcribe it, which matters because what gets dictated here is
/// a client conversation.
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _ready = false;

  bool get isListening => _speech.isListening;

  /// Whether the device can transcribe at all.
  ///
  /// False on an emulator without speech services, and on a device where the
  /// user has refused the microphone. The caller falls back to the keyboard —
  /// dictation is the fast path, never the only path.
  Future<bool> initialize() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onError: (dynamic _) {},
        onStatus: (String _) {},
      );
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  /// Start transcribing. [onResult] fires repeatedly as the guess improves.
  ///
  /// Partial results are on so the rep can see it hearing them; a silent box
  /// during dictation reads as broken and they start again.
  Future<bool> start({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!await initialize()) return false;
    await _speech.listen(
      onResult: (dynamic result) {
        onResult(
          (result.recognizedWords as String?) ?? '',
          (result.finalResult as bool?) ?? false,
        );
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
      // Long enough for a whole thought, and a pause long enough that thinking
      // mid-sentence does not end the recording.
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 4),
    );
    return true;
  }

  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }

  Future<void> cancel() async {
    if (_speech.isListening) await _speech.cancel();
  }
}
