import '../models/meeting.dart';
import '../services/calendar/calendar_service.dart';

/// Reads the day's meetings via a [CalendarService] (Google Calendar in
/// production, mock in demo/tests) and tracks which have been captured (F3).
class MeetingRepository {
  MeetingRepository({required CalendarService calendar}) : _calendar = calendar;

  final CalendarService _calendar;
  final Set<String> _captured = <String>{};
  List<Meeting> _cache = <Meeting>[];

  Future<List<Meeting>> today() async {
    final DateTime now = DateTime.now();
    final DateTime from = DateTime(now.year, now.month, now.day);
    final DateTime to = from.add(const Duration(days: 1));

    final List<Meeting> events = await _calendar.events(from: from, to: to);
    _cache = events
        .map((Meeting m) =>
            _captured.contains(m.id) ? m.copyWith(captured: true) : m)
        .toList()
      ..sort((Meeting a, Meeting b) => a.start.compareTo(b.start));
    return _cache;
  }

  /// Meetings that have ended, are eligible, and not yet captured (F3 prompt).
  Future<List<Meeting>> awaitingCapture() async {
    final List<Meeting> all = _cache.isEmpty ? await today() : _cache;
    return all.where((Meeting m) => m.awaitingCapture).toList();
  }

  Meeting? byId(String id) {
    for (final Meeting m in _cache) {
      if (m.id == id) return m;
    }
    return null;
  }

  void markCaptured(String id) {
    _captured.add(id);
    _cache = _cache
        .map((Meeting m) => m.id == id ? m.copyWith(captured: true) : m)
        .toList();
  }
}
