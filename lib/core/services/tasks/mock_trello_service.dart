import '../../constants/app_constants.dart';
import 'trello_service.dart';

/// Offline stand-in: pretends to create a Trello card and returns a board URL
/// so the task → Trello flow is demonstrable without credentials.
class MockTrelloService implements TrelloService {
  const MockTrelloService();

  @override
  Future<TrelloResult> createCard({
    required String title,
    String? description,
    DateTime? due,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return const TrelloResult(ok: true, cardUrl: 'https://trello.com/');
  }
}
