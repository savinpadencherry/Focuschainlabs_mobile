import '../../models/conversation.dart';
import '../../models/extraction.dart';
import '../../models/lookup.dart';

/// Contract for the AI layer (spec §9). The app depends only on this interface;
/// [MockAiService] backs demo mode and a real Gemini/Claude implementation can
/// be dropped in without touching feature code.
abstract interface class AiService {
  /// Transcript + fixed schema → structured [Extraction] (F2/F4).
  Future<Extraction> extract(String transcript);

  /// A grounded answer over the tenant's own data (F1). [clientHints] are the
  /// known client names used for entity resolution / RAG retrieval.
  Future<LookupAnswer> lookup(String query, {required List<String> clientHints});

  /// One turn of the capture conversation: given the dialogue so far, return
  /// the next conversational reply, and — once enough has been gathered — the
  /// final [Extraction] to write (create/update). [clientHints] are existing
  /// CRM client names so Gemini reuses the exact name (update vs create).
  Future<ConversationResult> converse({
    required List<ConversationMessage> history,
    required List<String> clientHints,
  });
}

