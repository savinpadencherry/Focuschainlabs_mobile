import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/get.dart';
import 'core/services/firebase/firebase_bootstrap.dart';
import 'core/services/push/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load keys from the bundled .env (optional — the app runs on mocks without it).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No/empty .env: fall back to --dart-define and the offline mocks.
  }
  // Initialise Firebase from native config; degrades to demo mode if absent.
  await FirebaseBootstrap.init();
  initializeGetIt();
  // Register for push (no-op until Firebase + APNs/FCM are configured).
  unawaited(PushService().init());
  runApp(const MrRexApp());
}
