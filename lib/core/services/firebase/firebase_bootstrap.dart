import 'package:firebase_core/firebase_core.dart';

/// Initialises Firebase from the native config (`google-services.json` /
/// `GoogleService-Info.plist`). If config is absent (e.g. before you add the
/// files, on web without generated options, or in tests) it degrades to demo
/// mode so the app still runs — every Firebase-backed service checks [ready].
///
/// After running `flutterfire configure`, switch [init] to pass
/// `options: DefaultFirebaseOptions.currentPlatform` for full web support.
abstract final class FirebaseBootstrap {
  static bool ready = false;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      ready = true;
    } catch (_) {
      ready = false;
    }
  }
}
