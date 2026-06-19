/// A single (possibly partial) speech-to-text result.
class VoiceResult {
  const VoiceResult(this.text, {this.isFinal = false});

  final String text;
  final bool isFinal;
}

/// Speech-to-text contract (spec §7 / decision D5: on-device STT). The UI
/// streams partial transcripts live into the composer; [DeviceVoiceService]
/// backs it with the platform recogniser, with a mock for tests/demo.
abstract interface class VoiceService {
  /// Initialise the engine and request microphone permission. Returns false if
  /// speech isn't available on this device/platform (the UI then falls back to
  /// typing).
  Future<bool> available();

  /// Begin listening. [onResult] fires repeatedly with growing partial text;
  /// [onDone] fires when recognition stops (silence, final result, or error).
  Future<void> listen({
    required void Function(VoiceResult result) onResult,
    void Function()? onDone,
  });

  Future<void> stop();

  bool get isListening;
}
