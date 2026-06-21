import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../models/conversation.dart';
import '../../models/extraction.dart';
import '../../models/lookup.dart';
import 'ai_service.dart';

/// Real [AiService] backed by Google's Gemini API (decision: Gemini 2.5 Flash,
/// key injected via --dart-define). Extraction uses JSON mode + a response
/// schema so the model returns the spec's exact shape; the result is still
/// validated before any CRM write.
class GeminiAiService implements AiService {
  GeminiAiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri get _endpoint => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}',
      );

  @override
  Future<Extraction> extract(String transcript) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'contents': <dynamic>[
        <String, dynamic>{
          'role': 'user',
          'parts': <dynamic>[
            <String, dynamic>{'text': _extractPrompt(transcript)},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': 0.2,
        'responseMimeType': 'application/json',
        'responseSchema': _extractionSchema,
      },
    };

    final String raw = await _generate(body);
    try {
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      return Extraction.fromJson(json);
    } catch (_) {
      throw const FormatException('Could not parse the extracted update.');
    }
  }

  @override
  Future<LookupAnswer> lookup(
    String query, {
    required List<String> clientHints,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'contents': <dynamic>[
        <String, dynamic>{
          'role': 'user',
          'parts': <dynamic>[
            <String, dynamic>{'text': _lookupPrompt(query, clientHints)},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{'temperature': 0.3},
    };
    try {
      final String text = await _generate(body);
      return LookupAnswer(answer: text.trim());
    } catch (_) {
      return const LookupAnswer(
        answer: 'I couldn’t reach the knowledge service just now. '
            'Please try again in a moment.',
      );
    }
  }

  @override
  Future<ConversationResult> converse({
    required List<ConversationMessage> history,
    required List<String> clientHints,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'systemInstruction': <String, dynamic>{
        'parts': <dynamic>[
          <String, dynamic>{'text': _conversePrompt(clientHints)},
        ],
      },
      'contents': history
          .where((ConversationMessage m) => !m.pending)
          .map((ConversationMessage m) => m.toGeminiTurn())
          .toList(),
      'generationConfig': <String, dynamic>{
        'temperature': 0.5,
        'responseMimeType': 'application/json',
        'responseSchema': _conversationSchema,
      },
    };
    final String raw = await _generate(body);
    return ConversationResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // --- HTTP ------------------------------------------------------------------

  Future<String> _generate(Map<String, dynamic> body) async {
    final http.Response res = await _client
        .post(
          _endpoint,
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw http.ClientException('Gemini error ${res.statusCode}: ${res.body}');
    }
    final Map<String, dynamic> json =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List<dynamic>? candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const FormatException('Gemini returned no candidates.');
    }
    final Map<String, dynamic> content =
        (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>;
    final List<dynamic> parts = content['parts'] as List<dynamic>;
    return parts
        .map((dynamic p) => (p as Map<String, dynamic>)['text']?.toString() ?? '')
        .join();
  }

  // --- Prompts ---------------------------------------------------------------

  String _extractPrompt(String transcript) => '''
You are Mr. Rex, a sales CRM assistant. Convert the rep's spoken note into a
single structured CRM update. Follow these rules strictly:
- Return ONLY JSON matching the provided schema.
- Decide "destination": "trello" if the note is primarily an actionable
  task/to-do/follow-up the rep must DO; "crm" if it is information about a lead
  or client to RECORD (a comment, interaction, or stage change).
- If destination is "trello", set "trello_action": "create" (a new task),
  "move" (move an existing card to another list), "update" (edit a card),
  "complete" (mark a card done), or "delete" (remove a card). For everything
  except create, set "trello_target_card" to the existing card's title/topic;
  for "move" also set "trello_target_list" to the destination list name.
- update_type is one of: comment, interaction, stage_change, follow_up.
- sentiment is one of: positive, neutral, negative, at_risk.
- Dates are ISO YYYY-MM-DD. Use null for anything not stated; never invent facts.
- "client" is the company/person the note is about; "" if truly unknown.

Rep's note:
"$transcript"''';

  String _lookupPrompt(String query, List<String> hints) => '''
You are Mr. Rex, a concise sales assistant. Answer the rep's question in 1-3
sentences. Only use facts implied by the question or these known clients:
${hints.join(', ')}. If you don't know, say so plainly — never invent specifics.

Question: "$query"''';

  String _conversePrompt(List<String> hints) => '''
You are Mr. Rex, a warm, sharp sales assistant talking with a rep right after a
client interaction. Have a short, natural back-and-forth to gather enough to log
a CRM update. Ask ONE concise question at a time about the things that matter:
what was discussed, whether budget/finances came up and how much, whether the
scope was confirmed, whether the work/deal is confirmed, overall sentiment, and
any follow-up date. Sound human and encouraging — not like a form.

Existing CRM clients (reuse the EXACT name if the rep means one of these, so we
update instead of duplicating): ${hints.isEmpty ? '(none yet)' : hints.join(', ')}.

Each turn return ONLY JSON: { "reply": string, "done": boolean,
"extraction": <object|null> }.
- While you still need more, set done=false, extraction=null, and put your next
  question in "reply".
- Once you have enough (usually after 2-4 exchanges, or when the rep signals
  they're done), set done=true, put a brief confirmation in "reply", and fill
  "extraction" with the structured record (same field rules as a single capture;
  null for unknowns, never invent). "client" must be the company/person; if it
  matches an existing client above, use that exact name.''';

  static const Map<String, dynamic> _extractionSchema = <String, dynamic>{
    'type': 'OBJECT',
    'properties': <String, dynamic>{
      'client': <String, dynamic>{'type': 'STRING'},
      'update_type': <String, dynamic>{
        'type': 'STRING',
        'enum': <String>['comment', 'interaction', 'stage_change', 'follow_up'],
      },
      'summary': <String, dynamic>{'type': 'STRING'},
      'sentiment': <String, dynamic>{
        'type': 'STRING',
        'enum': <String>['positive', 'neutral', 'negative', 'at_risk'],
      },
      'destination': <String, dynamic>{
        'type': 'STRING',
        'enum': <String>['crm', 'trello'],
      },
      'trello_action': <String, dynamic>{
        'type': 'STRING',
        'enum': <String>['create', 'move', 'update', 'complete', 'delete'],
      },
      'trello_target_card': <String, dynamic>{'type': 'STRING', 'nullable': true},
      'trello_target_list': <String, dynamic>{'type': 'STRING', 'nullable': true},
      'deal_stage_change': <String, dynamic>{'type': 'STRING', 'nullable': true},
      'next_steps': <String, dynamic>{
        'type': 'ARRAY',
        'items': <String, dynamic>{'type': 'STRING'},
      },
      'action_items': <String, dynamic>{
        'type': 'ARRAY',
        'items': <String, dynamic>{
          'type': 'OBJECT',
          'properties': <String, dynamic>{
            'title': <String, dynamic>{'type': 'STRING'},
            'due': <String, dynamic>{'type': 'STRING', 'nullable': true},
            'owner': <String, dynamic>{'type': 'STRING', 'nullable': true},
          },
          'required': <String>['title'],
        },
      },
      'follow_up_date': <String, dynamic>{'type': 'STRING', 'nullable': true},
      'notes': <String, dynamic>{'type': 'STRING', 'nullable': true},
    },
    'required': <String>['client', 'update_type', 'summary', 'sentiment', 'destination'],
  };

  Map<String, dynamic> get _conversationSchema => <String, dynamic>{
        'type': 'OBJECT',
        'properties': <String, dynamic>{
          'reply': <String, dynamic>{'type': 'STRING'},
          'done': <String, dynamic>{'type': 'BOOLEAN'},
          'extraction': <String, dynamic>{..._extractionSchema, 'nullable': true},
        },
        'required': <String>['reply', 'done'],
      };
}
