import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load keys from the bundled .env (optional — the app runs on mocks without it).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No/empty .env: fall back to --dart-define and the offline mocks.
  }
  initializeGetIt();
  runApp(const MrRexApp());
}
