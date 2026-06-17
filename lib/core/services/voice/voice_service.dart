import 'dart:async';
import 'dart:math';

/// Speech-to-text contract (spec §7, decision D5 — on-device vs hosted STT).
/// The UI depends only on this; the real provider plugs in behind it.
abstract interface class VoiceService {
  /// Whether mic permission/availability allows live capture.
  Future<bool> isAvailable();

  /// Simulated/real transcript. In demo mode a representative note is returned
  /// so the downstream extraction → review → write loop is exercised.
  Future<String> transcribe();
}

/// Offline stand-in that returns a realistic spoken note after a short delay.
class MockVoiceService implements VoiceService {
  const MockVoiceService();

  static const List<String> _samples = <String>[
    'Called Acme, they want a revised quote by Friday, deal looks warm.',
    'Met Northstar for the product walkthrough, keen on a two-depot pilot next week.',
    'Spoke to Zephyr, they pushed back on pricing and are comparing alternatives, deal at risk.',
  ];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<String> transcribe() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _samples[Random().nextInt(_samples.length)];
  }
}
