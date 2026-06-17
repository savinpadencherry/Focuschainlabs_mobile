import '../constants/app_constants.dart';
import '../data/seed_data.dart';
import '../models/meeting.dart';

/// Reads calendar meetings (spec §7 calendar read) and tracks which have been
/// captured. The server-side cron that detects just-ended meetings (F3) lives
/// in Supabase Edge Functions; this client repo just reads and marks state.
class MeetingRepository {
  final List<Meeting> _meetings = SeedData.meetings();

  Future<List<Meeting>> today() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final List<Meeting> sorted = List<Meeting>.of(_meetings)
      ..sort((Meeting a, Meeting b) => a.start.compareTo(b.start));
    return sorted;
  }

  /// Meetings that have ended, are eligible, and not yet captured (F3 prompt).
  Future<List<Meeting>> awaitingCapture() async {
    final List<Meeting> all = await today();
    return all.where((Meeting m) => m.awaitingCapture).toList();
  }

  Meeting? byId(String id) {
    for (final Meeting m in _meetings) {
      if (m.id == id) return m;
    }
    return null;
  }

  void markCaptured(String id) {
    final int i = _meetings.indexWhere((Meeting m) => m.id == id);
    if (i != -1) _meetings[i] = _meetings[i].copyWith(captured: true);
  }
}
