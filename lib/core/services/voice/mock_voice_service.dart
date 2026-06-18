import 'voice_service.dart';

/// Offline stand-in that streams a realistic note word-by-word, so the capture
/// loop is demonstrable in tests and on platforms without a recogniser.
class MockVoiceService implements VoiceService {
  bool _listening = false;

  static const String _sample =
      'Called Acme, they want a revised quote by Friday, deal looks warm.';

  @override
  bool get isListening => _listening;

  @override
  Future<bool> available() async => true;

  @override
  Future<void> listen({
    required void Function(VoiceResult result) onResult,
    void Function()? onDone,
  }) async {
    _listening = true;
    final List<String> words = _sample.split(' ');
    final StringBuffer acc = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      if (!_listening) break;
      await Future<void>.delayed(const Duration(milliseconds: 90));
      acc.write(i == 0 ? words[i] : ' ${words[i]}');
      onResult(VoiceResult(acc.toString(), isFinal: i == words.length - 1));
    }
    _listening = false;
    onDone?.call();
  }

  @override
  Future<void> stop() async => _listening = false;
}
