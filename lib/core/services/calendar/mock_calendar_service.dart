import '../../constants/app_constants.dart';
import '../../data/seed_data.dart';
import '../../models/meeting.dart';
import 'calendar_service.dart';

/// Seeded calendar for demo mode and tests.
class MockCalendarService implements CalendarService {
  const MockCalendarService();

  @override
  Future<List<Meeting>> events({
    required DateTime from,
    required DateTime to,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return SeedData.meetings()
        .where((Meeting m) => m.start.isAfter(from) && m.start.isBefore(to))
        .toList();
  }
}
