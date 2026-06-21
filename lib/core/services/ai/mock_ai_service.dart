import '../../constants/app_constants.dart';
import '../../data/seed_data.dart';
import '../../models/client_brief.dart';
import '../../models/conversation.dart';
import '../../models/enums.dart';
import '../../models/extraction.dart';
import '../../models/lookup.dart';
import 'ai_service.dart';

/// Heuristic, offline stand-in for the Claude API. It parses a spoken note into
/// the spec's extraction schema and answers lookups from seeded knowledge, so
/// the full MVP loop is demonstrable with no API key. Swap for a real
/// implementation behind [AiService] (see docs/SETUP.md).
class MockAiService implements AiService {
  const MockAiService();

  @override
  Future<Extraction> extract(String transcript) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final String text = transcript.trim();
    final String lower = text.toLowerCase();

    final String client = _resolveClient(lower);
    final Sentiment sentiment = _resolveSentiment(lower);
    final UpdateType type = _resolveType(lower);
    final DateTime? followUp = _resolveFollowUp(lower);
    final List<ActionItem> actions = _resolveActionItems(text, followUp);
    final String? stageChange = _resolveStage(lower);
    final bool taskish = type == UpdateType.followUp ||
        _containsAny(lower, <String>['todo', 'to-do', 'task', 'remind', 'schedule', 'book ',
          'move', 'mark done', 'complete', 'delete', 'remove']);
    final String destination = taskish ? 'trello' : 'crm';

    String trelloAction = 'create';
    String? targetCard;
    if (destination == 'trello') {
      if (_containsAny(lower, <String>['mark done', 'done', 'completed', 'finished', 'close'])) {
        trelloAction = 'complete';
      } else if (_containsAny(lower, <String>['delete', 'remove', 'cancel'])) {
        trelloAction = 'delete';
      } else if (_containsAny(lower, <String>['move', 'shift'])) {
        trelloAction = 'move';
      } else if (_containsAny(lower, <String>['update', 'change', 'edit', 'rename'])) {
        trelloAction = 'update';
      }
      if (trelloAction != 'create') {
        targetCard = client != 'Unknown client' ? client : _summarise(text);
      }
    }

    return Extraction(
      client: client,
      updateType: type,
      summary: _summarise(text),
      sentiment: sentiment,
      destination: destination,
      trelloAction: trelloAction,
      trelloTargetCard: targetCard,
      dealStageChange: stageChange,
      nextSteps: actions.map((ActionItem a) => a.title).toList(),
      actionItems: actions,
      followUpDate: followUp,
      notes: text.length > 140 ? text : null,
    );
  }

  @override
  Future<ConversationResult> converse({
    required List<ConversationMessage> history,
    required List<String> clientHints,
    String? clientContext,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final List<ConversationMessage> userMsgs =
        history.where((ConversationMessage m) => m.role == ChatRole.user).toList();
    final int turns = userMsgs.length;
    const List<String> questions = <String>[
      'Nice — how did it go? Was the scope or budget discussed?',
      'Got it. Is the work confirmed, and is there a follow-up date?',
    ];
    if (turns < 3) {
      return ConversationResult(
        reply: questions[(turns - 1).clamp(0, questions.length - 1)],
        done: false,
      );
    }
    final String full = userMsgs.map((ConversationMessage m) => m.text).join('. ');
    final Extraction extraction = await extract(full);
    return ConversationResult(
      reply: 'Perfect — here’s what I’ll save to the CRM. Tap save to confirm.',
      done: true,
      extraction: extraction,
    );
  }

  @override
  Future<ClientBrief> brief({
    required String clientName,
    required String context,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final cl = SeedData.clients().firstWhere(
      (c) => c.name.toLowerCase().contains(
            clientName.toLowerCase().split(' ').first,
          ),
      orElse: () => SeedData.clients().first,
    );
    final String last = cl.interactions.isEmpty
        ? 'No interactions logged yet'
        : cl.interactions.first.summary;
    return ClientBrief(
      headline:
          '${cl.name} is ${cl.sentiment.label.toLowerCase()} — $last.',
      opener:
          'Good to reconnect — last time we spoke about ${last.toLowerCase()}. '
          'How are things looking on your side?',
      talkingPoints: <String>[
        if (cl.interactions.isNotEmpty) 'Recap: $last',
        'Reaffirm the value and next milestone',
        if (cl.pendingFollowUps.isNotEmpty)
          'Pending: ${cl.pendingFollowUps.join(', ')}',
      ],
      thingsToConfirm: <String>[
        'Is the budget confirmed, and for how much?',
        'Is the scope locked, or still being shaped?',
        'Who signs off, and what is the timeline?',
      ],
      risks: <String>[
        if (cl.sentiment.label.toLowerCase().contains('risk'))
          'Sentiment is at-risk — listen for hesitation or competitors',
      ],
    );
  }

  @override
  Future<LookupAnswer> lookup(
    String query, {
    required List<String> clientHints,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final String lower = query.toLowerCase();

    // Client 360 if the query names a known client.
    for (final String name in clientHints) {
      if (lower.contains(name.toLowerCase().split(' ').first)) {
        final cl = SeedData.clients().firstWhere(
          (c) => c.name.toLowerCase().contains(name.toLowerCase().split(' ').first),
          orElse: () => SeedData.clients().first,
        );
        return LookupAnswer(
          clientId: cl.id,
          answer:
              '${cl.name} — sentiment ${cl.sentiment.label.toLowerCase()}. '
              '${cl.interactions.isEmpty ? 'No recent interactions.' : cl.interactions.first.summary} '
              '${cl.pendingFollowUps.isEmpty ? '' : 'Pending: ${cl.pendingFollowUps.join(', ')}.'}',
          citations: <Citation>[
            Citation(label: '${cl.name} · CRM record', type: 'CRM record'),
            if (cl.recentEmailSubjects.isNotEmpty)
              Citation(label: cl.recentEmailSubjects.first, type: 'Email'),
          ],
        );
      }
    }

    // Otherwise answer from product knowledge.
    for (final MapEntry<String, String> entry
        in SeedData.productKnowledge.entries) {
      if (lower.contains(entry.key)) {
        return LookupAnswer(
          answer: entry.value,
          citations: <Citation>[
            Citation(label: '${entry.key} — product doc', type: 'Product doc'),
          ],
        );
      }
    }

    return const LookupAnswer(
      answer:
          'I can pull up any client (try “what’s the latest on Acme?”) or '
          'answer product questions like pricing, the configurator scope, or '
          'how pilots work. Everything I return is grounded in your org’s data.',
    );
  }

  // --- Heuristics -----------------------------------------------------------

  String _resolveClient(String lower) {
    for (final String name in SeedData.clients().map((c) => c.name)) {
      final String first = name.toLowerCase().split(' ').first;
      if (lower.contains(first)) return name;
    }
    return 'Unknown client';
  }

  Sentiment _resolveSentiment(String lower) {
    if (_containsAny(lower, <String>['at risk', 'churn', 'unhappy', 'pushed back', 'comparing'])) {
      return Sentiment.atRisk;
    }
    if (_containsAny(lower, <String>['warm', 'keen', 'excited', 'positive', 'looking good', 'great'])) {
      return Sentiment.positive;
    }
    if (_containsAny(lower, <String>['concern', 'worried', 'delay', 'lost', 'cold'])) {
      return Sentiment.negative;
    }
    return Sentiment.neutral;
  }

  UpdateType _resolveType(String lower) {
    if (_containsAny(lower, <String>['stage', 'moved to', 'warm', 'won', 'closed', 'negotiation'])) {
      return UpdateType.stageChange;
    }
    if (_containsAny(lower, <String>['by friday', 'next week', 'follow up', 'follow-up', 'call back', 'remind'])) {
      return UpdateType.followUp;
    }
    if (_containsAny(lower, <String>['called', 'met', 'spoke', 'meeting', 'demo', 'walkthrough'])) {
      return UpdateType.interaction;
    }
    return UpdateType.comment;
  }

  String? _resolveStage(String lower) {
    if (lower.contains('warm')) return 'Warm';
    if (lower.contains('negotiation')) return 'Negotiation';
    if (lower.contains('won') || lower.contains('closed')) return 'Won';
    if (lower.contains('proposal')) return 'Proposal';
    return null;
  }

  DateTime? _resolveFollowUp(String lower) {
    final DateTime now = DateTime.now();
    const List<String> days = <String>[
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
    ];
    for (int i = 0; i < days.length; i++) {
      if (lower.contains(days[i])) {
        int delta = (i + 1) - now.weekday;
        if (delta <= 0) delta += 7;
        return DateTime(now.year, now.month, now.day + delta, 9);
      }
    }
    if (lower.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1, 9);
    }
    if (lower.contains('next week')) {
      return DateTime(now.year, now.month, now.day + 7, 9);
    }
    return null;
  }

  List<ActionItem> _resolveActionItems(String text, DateTime? due) {
    final List<ActionItem> items = <ActionItem>[];
    final String lower = text.toLowerCase();
    if (_containsAny(lower, <String>['quote', 'quotation'])) {
      items.add(ActionItem(title: 'Send revised quote', due: due, owner: 'Me'));
    }
    if (_containsAny(lower, <String>['deck', 'proposal', 'scope'])) {
      items.add(ActionItem(title: 'Share scope / proposal deck', due: due));
    }
    if (_containsAny(lower, <String>['sow', 'contract', 'agreement'])) {
      items.add(ActionItem(title: 'Prepare SOW / contract', due: due));
    }
    if (items.isEmpty && due != null) {
      items.add(ActionItem(title: 'Follow up', due: due, owner: 'Me'));
    }
    return items;
  }

  String _summarise(String text) {
    if (text.isEmpty) return 'Spoken note captured.';
    final String first = text.split(RegExp(r'[.!?]')).first.trim();
    final String s = first.isEmpty ? text : first;
    return s.length > 120 ? '${s.substring(0, 117)}…' : s;
  }

  bool _containsAny(String haystack, List<String> needles) =>
      needles.any(haystack.contains);
}
