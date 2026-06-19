import '../../constants/app_constants.dart';
import 'trello_service.dart';

/// Offline stand-in: pretends to manage Trello cards and returns a board URL so
/// the task flow is demonstrable without credentials.
class MockTrelloService implements TrelloService {
  const MockTrelloService();

  static const String _board = 'https://trello.com/';

  Future<TrelloResult> _ok(String action) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return TrelloResult(ok: true, cardUrl: _board, action: action);
  }

  @override
  Future<TrelloResult> createCard({
    required String title,
    String? description,
    DateTime? due,
  }) =>
      _ok('created');

  @override
  Future<List<TrelloCardRef>> findCards(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return <TrelloCardRef>[
      TrelloCardRef(id: 'mock-card', name: query, listId: 'mock-list', url: _board),
    ];
  }

  @override
  Future<List<TrelloListRef>> lists() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const <TrelloListRef>[
      TrelloListRef(id: 'l1', name: 'Todo'),
      TrelloListRef(id: 'l2', name: 'Develop/work'),
      TrelloListRef(id: 'l3', name: 'Verify'),
    ];
  }

  @override
  Future<TrelloResult> moveCard(String cardId, String listId) => _ok('moved');

  @override
  Future<TrelloResult> updateCard(String cardId,
          {String? name, String? description, DateTime? due}) =>
      _ok('updated');

  @override
  Future<TrelloResult> completeCard(String cardId) => _ok('completed');

  @override
  Future<TrelloResult> deleteCard(String cardId) => _ok('deleted');
}
