import 'package:equatable/equatable.dart';

/// Outcome of creating a Trello card.
class TrelloResult extends Equatable {
  const TrelloResult({required this.ok, this.cardUrl, this.error});

  const TrelloResult.failure(this.error)
      : ok = false,
        cardUrl = null;

  final bool ok;
  final String? cardUrl;
  final String? error;

  @override
  List<Object?> get props => <Object?>[ok, cardUrl, error];
}

/// Contract for pushing action items to Trello (F6). The HTTP implementation
/// calls Trello's REST API directly (decision: app-side, key/token via config).
abstract interface class TrelloService {
  Future<TrelloResult> createCard({
    required String title,
    String? description,
    DateTime? due,
  });
}
