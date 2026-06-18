import '../../models/meeting.dart';

/// Reads calendar meetings for a date range (spec §7 calendar read). Backed by
/// Google Calendar in production and a mock for tests/demo.
abstract interface class CalendarService {
  Future<List<Meeting>> events({required DateTime from, required DateTime to});
}
