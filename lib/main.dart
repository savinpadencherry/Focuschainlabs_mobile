import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/get.dart';
import 'core/services/firebase/firebase_bootstrap.dart';
import 'core/services/navigator_service.dart';
import 'core/services/push/push_service.dart';
import 'core/services/reminders/reminder_service.dart';
import 'features/capture/view/conversation_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load keys from the bundled .env (optional — the app runs on mocks without it).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No/empty .env: fall back to --dart-define and the offline mocks.
  }
  // Backends — each degrades to demo mode if its config/keys are absent.
  await FirebaseBootstrap.init();
  initializeGetIt();
  unawaited(PushService().init());
  unawaited(app<ReminderService>().init(onTap: _openCaptureFromNotification));
  runApp(const MrRexApp());
}

/// Tapping a post-meeting reminder opens the capture screen.
void _openCaptureFromNotification(String? payload) {
  final BuildContext? context = app<NavigatorService>().navigatorKey.currentContext;
  if (context != null) ConversationView.open(context);
}
