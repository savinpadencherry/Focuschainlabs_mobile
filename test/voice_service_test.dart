import 'package:flutter_test/flutter_test.dart';

import 'package:focuschainlabs_mobile/core/services/voice/voice_service.dart';

void main() {
  test('mock voice streams partial then final transcript', () async {
    final MockVoiceService voice = MockVoiceService();
    final List<String> partials = <String>[];
    String? finalText;

    await voice.startListening(
      onResult: (String transcript, bool isFinal) {
        if (isFinal) {
          finalText = transcript;
        } else {
          partials.add(transcript);
        }
      },
      onError: (_) {},
    );

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await voice.stopListening();

    expect(partials, isNotEmpty);
    expect(finalText, isNotNull);
    expect(finalText!.trim().isNotEmpty, isTrue);
  });

  test('cancelListening stops without final append', () async {
    final MockVoiceService voice = MockVoiceService();
    await voice.startListening(onResult: (_, __) {}, onError: (_) {});
    await voice.cancelListening();
    expect(voice.isListening, isFalse);
  });
}
