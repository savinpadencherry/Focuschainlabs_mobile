import '../models/lookup.dart';
import '../services/ai/ai_service.dart';
import 'client_repository.dart';

/// Backs F1 conversational lookup: routes a query to the AI layer with the
/// tenant's client names as grounding hints, and returns a cited answer.
class LookupRepository {
  LookupRepository({required AiService ai, required ClientRepository clients})
      : _ai = ai,
        _clients = clients;

  final AiService _ai;
  final ClientRepository _clients;

  Future<LookupAnswer> ask(String query) {
    return _ai.lookup(query, clientHints: _clients.clientNames());
  }
}
