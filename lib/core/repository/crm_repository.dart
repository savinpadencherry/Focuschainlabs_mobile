import '../models/listing.dart';
import '../models/ona.dart';
import '../models/pipeline.dart';
import '../services/api/secona_api.dart';

/// Everything the app reads from and writes to the shared CRM.
///
/// One repository rather than three, because the three surfaces are not
/// independent: Ona hands off to the share composer, the composer needs a
/// lead from the pipeline, and a write from any of them changes what the
/// others show. Splitting them would mean the split had to be undone at every
/// call site.
///
/// There is no local cache and no offline queue. A CRM that shows a rep a
/// stale pipeline while telling them it is live is worse than one that says it
/// could not reach the server, and a write that silently queues is a write the
/// rep believes has happened.
class CrmRepository {
  CrmRepository({required SeconaApi api}) : _api = api;

  final SeconaApi _api;

  // ── identity ────────────────────────────────────────────────────────────────

  /// Who the CRM thinks the signed-in user is. Throws [ApiException] with
  /// `isNotAMember` when the Google account is not on the invite list.
  Future<Me> me() async => Me.fromJson(await _api.get('/api/me'));

  // ── pipeline ────────────────────────────────────────────────────────────────

  Future<PipelineBoard> board({String stage = '', String search = ''}) async {
    return PipelineBoard.fromJson(await _api.get(
      '/api/pipeline',
      query: <String, dynamic>{'stage': stage, 'search': search},
    ));
  }

  Future<Lead> lead(String id) async =>
      Lead.fromJson(await _api.get('/api/pipeline/lead/$id'));

  /// Move a lead to a new stage. Returns the lead as stored.
  Future<Lead> moveStage(String id, Stage stage) async {
    final Map<String, dynamic> res = await _api.post(
      '/api/pipeline/lead/$id/stage',
      body: <String, dynamic>{'stage': stage.key},
    );
    return Lead.fromJson(asMap(res['lead']));
  }

  /// Append a note to a lead's timeline. Returns the lead as stored, so the
  /// caller can show a receipt rather than assuming the write landed.
  Future<Lead> logActivity(String id, String note) async {
    final Map<String, dynamic> res = await _api.post(
      '/api/pipeline/lead/$id/activity',
      body: <String, dynamic>{'note': note},
    );
    return Lead.fromJson(asMap(res['lead']));
  }

  Future<Lead> updateLead(String id, Map<String, dynamic> changes) async {
    final Map<String, dynamic> res = await _api.post(
      '/api/pipeline/lead/$id',
      body: <String, dynamic>{'changes': changes},
    );
    return Lead.fromJson(asMap(res['lead']));
  }

  // ── listings ────────────────────────────────────────────────────────────────

  Future<ListingResults> listings(ListingFilters filters) async {
    return ListingResults.fromJson(
      await _api.get('/api/listings', query: filters.toQuery()),
    );
  }

  Future<Listing> listing(String id) async =>
      Listing.fromJson(await _api.get('/api/listings/$id'));

  /// Record that these properties went to this lead.
  ///
  /// Called after the user approved the share — this writes history, it does
  /// not decide to send.
  Future<int> recordShare({
    required List<String> listingIds,
    required String contactId,
    required String channel,
    String subject = '',
  }) async {
    final Map<String, dynamic> res = await _api.post(
      '/api/listings/share',
      body: <String, dynamic>{
        'listing_ids': listingIds,
        'contact_id': contactId,
        'channel': channel,
        'subject': subject,
      },
    );
    return asInt(res['recorded']);
  }

  /// Edit a property. Returns it as stored — normalisation rewrites a changed
  /// price into the numeric field that search actually filters on.
  Future<Listing> editListing(String id, Map<String, dynamic> changes) async {
    final Map<String, dynamic> res = await _api.post(
      '/api/listings/$id/edit',
      body: <String, dynamic>{'changes': changes},
    );
    return Listing.fromJson(asMap(res['listing']));
  }

  /// The questions a rep gets asked while standing in a property.
  Future<List<ListingQuestion>> listingQuestions(String id) async {
    final Map<String, dynamic> res =
        await _api.get('/api/listings/$id/questions');
    return asMaps(res['questions']).map(ListingQuestion.fromJson).toList();
  }

  /// Answer one, from the database. The server computes the facts in SQL and
  /// gives the model only those, so the number in the answer is a real number.
  Future<String> askAboutListing(String id, String questionId) async {
    final Map<String, dynamic> res = await _api.post(
      '/api/listings/$id/ask',
      body: <String, dynamic>{'question_id': questionId},
    );
    return asString(res['answer']);
  }

  // ── Ona ─────────────────────────────────────────────────────────────────────

  /// Ask Ona one thing.
  ///
  /// [fromChip] separates a tap from a sentence, and the distinction is not
  /// cosmetic: a chip carries wording the product wrote, so the server may
  /// answer it from keywords instantly. Anything a person typed goes to the
  /// language model, because the reason they typed it is that the chips did not
  /// cover what they meant.
  ///
  /// [pendingPlan] carries back the plan from a turn where Ona asked a
  /// clarifying question. The server holds no session, so the thread does.
  Future<OnaReply> ask(
    String query, {
    List<OnaTurn> history = const <OnaTurn>[],
    bool fromChip = false,
    Map<String, dynamic>? pendingPlan,
  }) async {
    return OnaReply.fromJson(await _api.post(
      '/api/ona/ask',
      body: <String, dynamic>{
        'query': query,
        'from_chip': fromChip,
        'history': _history(history),
        if (pendingPlan != null) 'pending_plan': pendingPlan,
      },
    ));
  }

  /// Run a plan the user has approved.
  Future<OnaReply> confirm(Map<String, dynamic> plan) async {
    return OnaReply.fromJson(
      await _api.post('/api/ona/confirm', body: <String, dynamic>{'plan': plan}),
    );
  }

  /// The morning brief.
  Future<OnaAnswer> briefing() async =>
      OnaAnswer.fromJson(await _api.get('/api/ona/briefing'));

  /// Perform a write the user explicitly confirmed. Returns the record as stored.
  Future<Lead> act(String action, Map<String, dynamic> params) async {
    final Map<String, dynamic> res = await _api.post(
      '/api/ona/act',
      body: <String, dynamic>{'action': action, 'params': params},
    );
    return Lead.fromJson(asMap(res['receipt']));
  }

  /// The last few turns, as the planner's prompt expects them.
  ///
  /// Trimmed to the recent tail: conversation history enters the model's prompt
  /// as delimited data, and an unbounded thread would eventually crowd out the
  /// question being asked.
  List<Map<String, String>> _history(List<OnaTurn> turns) {
    final List<OnaTurn> recent =
        turns.where((OnaTurn t) => !t.pending && t.text.isNotEmpty).toList();
    final int from = recent.length > 8 ? recent.length - 8 : 0;
    return recent
        .sublist(from)
        .map((OnaTurn t) => <String, String>{
              'role': t.isUser ? 'user' : 'assistant',
              'content': t.text,
            })
        .toList();
  }
}
