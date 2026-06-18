import 'dart:async';
import 'dart:math';

/// Speech-to-text contract. The UI depends only on this; a device-backed or
/// mock implementation plugs in behind it via GetIt.
abstract interface class VoiceService {
  /// Prepare the underlying STT engine (permissions, locale, etc.).
  Future<bool> initialize();

  /// Whether mic permission and platform support allow live capture.
  Future<bool> isAvailable();

  /// Begin listening. [onResult] fires for partial and final transcript chunks;
  /// [onError] reports permission, availability, or engine failures.
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(String message) onError,
  });

  Future<void> stopListening();
  Future<void> cancelListening();

  bool get isListening;
}

/// Offline stand-in for web, desktop, and tests. Simulates streaming partial
/// results then a final transcript so the capture loop is exercisable without
/// a microphone.
class MockVoiceService implements VoiceService {
  MockVoiceService();

  static const List<String> _samples = <String>[
    'Called Acme, they want a revised quote by Friday, deal looks warm.',
    'Met Northstar for the product walkthrough, keen on a two-depot pilot next week.',
    'Spoke to Zephyr, they pushed back on pricing and are comparing alternatives, deal at risk.',
  ];

  bool _listening = false;
  Timer? _timer;
  int _wordIndex = 0;
  List<String> _words = <String>[];
  void Function(String transcript, bool isFinal)? _onResult;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(String message) onError,
  }) async {
    if (_listening) return;
    _onResult = onResult;
    _listening = true;
    final String sample = _samples[Random().nextInt(_samples.length)];
    _words = sample.split(' ');
    _wordIndex = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 180), _tick);
  }

  void _tick(Timer timer) {
    if (!_listening) {
      timer.cancel();
      return;
    }
    if (_wordIndex >= _words.length) {
      timer.cancel();
      _listening = false;
      _onResult?.call(_words.join(' '), true);
      return;
    }
    _wordIndex++;
    _onResult?.call(_words.take(_wordIndex).join(' '), false);
  }

  @override
  Future<void> stopListening() async {
    _timer?.cancel();
    if (_listening && _onResult != null) {
      _onResult?.call(_words.join(' '), true);
    }
    _listening = false;
  }

  @override
  Future<void> cancelListening() async {
    _timer?.cancel();
    _listening = false;
    _wordIndex = 0;
    _words = <String>[];
  }
}
