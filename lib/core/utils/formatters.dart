import 'package:intl/intl.dart';

/// Date/time helpers used across the UI.
abstract final class Formatters {
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _day = DateFormat('EEE, d MMM');
  static final DateFormat _dayShort = DateFormat('d MMM');

  static String time(DateTime dt) => _time.format(dt);
  static String day(DateTime dt) => _day.format(dt);
  static String dayShort(DateTime dt) => _dayShort.format(dt);

  /// "18 minutes ago", "Yesterday", "Just now" — compact relative time.
  static String relative(DateTime dt) {
    final Duration diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return _dayShort.format(dt);
  }

  /// Greeting based on the time of day.
  static String greeting(DateTime now) {
    final int h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
