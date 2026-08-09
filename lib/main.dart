import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/get.dart';
import 'core/services/firebase/firebase_bootstrap.dart';
import 'core/services/push/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The API address is written into .env by the release workflow. A build
  // without it still starts; the surfaces report that they cannot reach the
  // CRM rather than showing invented data.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env bundled: fall back to --dart-define.
  }

  await FirebaseBootstrap.init();
  initializeGetIt();
  unawaited(PushService().init());

  runApp(const SeconaApp());
}
