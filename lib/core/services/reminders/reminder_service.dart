import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/meeting.dart';

/// Shows a local notification asking for an update when a calendar meeting has
/// ended (F3). Server-side detection sends real push later; this client check
/// fires when the app is opened/resumed, so the prompt is never missed even
/// without a backend cron. Each meeting is reminded at most once per session.
class ReminderService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final Set<String> _notified = <String>{};
  bool _inited = false;

  Future<void> init({void Function(String? payload)? onTap}) async {
    if (kIsWeb || _inited) return;
    try {
      const AndroidInitializationSettings android =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (NotificationResponse r) =>
            onTap?.call(r.payload),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _inited = true;
    } catch (_) {
      // Notifications unavailable — non-fatal (the home still shows the prompt).
    }
  }

  Future<void> remindEndedMeetings(List<Meeting> awaiting) async {
    if (kIsWeb || !_inited) return;
    for (final Meeting m in awaiting) {
      if (_notified.contains(m.id)) continue;
      _notified.add(m.id);
      try {
        await _plugin.show(
          m.id.hashCode & 0x7fffffff,
          'How did the meeting with ${m.clientName} go?',
          'Tap to capture the outcome of ${m.title}.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'captures',
              'Capture reminders',
              channelDescription: 'Prompts to capture a meeting outcome',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: m.id,
        );
      } catch (_) {
        // Ignore individual failures.
      }
    }
  }
}
