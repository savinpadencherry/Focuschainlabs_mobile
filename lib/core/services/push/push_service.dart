import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../firebase/firebase_bootstrap.dart';

/// Minimal FCM wiring for post-meeting reminders (F3). The meeting-ended
/// *detection* stays server-side; this only registers the device and handles
/// incoming messages. No-ops until Firebase is configured (and skipped on web,
/// which needs a VAPID key + service worker).
class PushService {
  Future<void> init() async {
    if (kIsWeb || !FirebaseBootstrap.ready) return;
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      // TODO: persist this token against the user/device, refresh on rotate,
      // and clear it on logout.
      await messaging.getToken();
      FirebaseMessaging.onMessage.listen((RemoteMessage _) {
        // TODO: show a local notification and deep-link into the capture screen.
      });
    } catch (_) {
      // Push unavailable — non-fatal.
    }
  }
}
