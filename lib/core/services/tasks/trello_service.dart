import 'package:equatable/equatable.dart';

/// Outcome of a Trello operation.
class TrelloResult extends Equatable {
  const TrelloResult({required this.ok, this.cardUrl, this.action, this.error});

  const TrelloResult.failure(this.error)
      : ok = false,
        cardUrl = null,
        action = null;

  final bool ok;
  final String? cardUrl;
  final String? action; // created | moved | updated | completed | deleted
  final String? error;

  @override
  List<Object?> get props => <Object?>[ok, cardUrl, action, error];
}

/// A lightweight reference to a Trello card.
class TrelloCardRef extends Equatable {
  const TrelloCardRef({required this.id, required this.name, required this.listId, this.url});

  final String id;
  final String name;
  final String listId;
  final String? url;

  @override
  List<Object?> get props => <Object?>[id, name, listId];
}

/// A Trello list (column) on the board.
class TrelloListRef extends Equatable {
  const TrelloListRef({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => <Object?>[id, name];
}

/// Contract for managing Trello cards (F6 + the conversational task actions).
/// The HTTP implementation talks to Trello's REST API directly; a mock backs
/// demo mode. All operations target the board derived from the configured list.
abstract interface class TrelloService {
  Future<TrelloResult> createCard({
    required String title,
    String? description,
    DateTime? due,
  });

  /// Open cards on the board whose name matches [query] (case-insensitive).
  Future<List<TrelloCardRef>> findCards(String query);

  /// The board's lists/columns (for moving cards).
  Future<List<TrelloListRef>> lists();

  Future<TrelloResult> moveCard(String cardId, String listId);

  Future<TrelloResult> updateCard(
    String cardId, {
    String? name,
    String? description,
    DateTime? due,
  });

  /// Mark the card complete (sets dueComplete).
  Future<TrelloResult> completeCard(String cardId);

  Future<TrelloResult> deleteCard(String cardId);
}
