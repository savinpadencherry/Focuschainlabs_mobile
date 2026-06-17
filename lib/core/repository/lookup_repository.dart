import '../models/client.dart';
import '../models/enums.dart';
import '../models/lookup.dart';
import '../services/ai/ai_service.dart';
import 'client_repository.dart';

/// Backs F1 conversational lookup. It first tries to resolve a known client
/// (so the answer is grounded in real CRM data and renders a client-360 card),
/// and otherwise defers to the AI layer for product/general questions. This
/// keeps grounding independent of which AI provider is wired.
class LookupRepository {
  LookupRepository({required AiService ai, required ClientRepository clients})
      : _ai = ai,
        _clients = clients;

  final AiService _ai;
  final ClientRepository _clients;

  Future<LookupAnswer> ask(String query) async {
    final Client? client = _matchClient(query);
    if (client != null) {
      return LookupAnswer(
        clientId: client.id,
        answer: _client360(client),
        citations: <Citation>[
          Citation(label: '${client.name} · CRM record', type: 'CRM record'),
          if (client.recentEmailSubjects.isNotEmpty)
            Citation(label: client.recentEmailSubjects.first, type: 'Email'),
        ],
      );
    }
    return _ai.lookup(query, clientHints: _clients.clientNames());
  }

  Client? _matchClient(String query) {
    final String q = query.toLowerCase();
    for (final Client c in _clients.cached) {
      final String first = c.name.toLowerCase().split(' ').first;
      if (first.length > 2 && q.contains(first)) return c;
    }
    return null;
  }

  String _client360(Client c) {
    final String latest = c.interactions.isEmpty
        ? 'No recent interactions logged.'
        : c.interactions.first.summary;
    final String deal = c.primaryDeal == null
        ? ''
        : ' Open deal: ${c.primaryDeal!.title} (${c.primaryDeal!.stage.label}, ${c.primaryDeal!.value}).';
    final String follow = c.pendingFollowUps.isEmpty
        ? ''
        : ' Pending: ${c.pendingFollowUps.join(', ')}.';
    return '${c.name} — sentiment ${c.sentiment.label.toLowerCase()}. $latest$deal$follow';
  }
}
