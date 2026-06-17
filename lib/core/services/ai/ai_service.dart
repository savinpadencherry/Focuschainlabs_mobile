import '../../models/extraction.dart';
import '../../models/lookup.dart';

/// Contract for the AI layer (spec §9 "Claude API"). The app depends only on
/// this interface; [MockAiService] backs demo mode and a real Claude-backed
/// implementation can be dropped in without touching feature code.
///
/// Both methods follow the spec's discipline: extraction returns the fixed
/// JSON schema and is validated before use; lookup answers are grounded and
/// must cite their source records/documents (no fabricated facts).
abstract interface class AiService {
  /// Transcript + fixed schema → structured [Extraction] (F2/F4).
  Future<Extraction> extract(String transcript);

  /// A grounded answer over the tenant's own data (F1). [clientHints] are the
  /// known client names used for entity resolution / RAG retrieval.
  Future<LookupAnswer> lookup(String query, {required List<String> clientHints});
}
