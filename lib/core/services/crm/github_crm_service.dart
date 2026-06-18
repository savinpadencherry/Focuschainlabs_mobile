import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../models/crm.dart';
import '../../models/enums.dart';
import '../../models/extraction.dart';
import 'crm_exceptions.dart';
import 'leads_crm_service.dart';

/// Reads and writes the Leads Agent CRM **directly in its GitHub repo**
/// (`data/crm/contacts.json`) via the Contents API — no separate server. This
/// is the same store the Streamlit CRM uses, so updates appear in both.
///
/// **DEMO DIRECT MODE ONLY** — credentials ship in the app bundle for internal
/// UAT. Production must route writes through a backend proxy / Edge Function.
///
/// Auth: a narrowly scoped PAT (`GITHUB_TOKEN`) with "Contents: read and write".
class GithubCrmService implements LeadsCrmService {
  GithubCrmService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const int _maxConflictRetries = 3;

  Uri get _contentsUri => Uri.parse(
        'https://api.github.com/repos/${AppConfig.githubCrmRepo}'
        '/contents/${AppConfig.githubCrmPath}',
      );

  Map<String, String> get _headers => <String, String>{
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer ${AppConfig.githubToken}',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  // --- read -----------------------------------------------------------------

  /// Returns the parsed CRM document and the file SHA (needed to write back).
  Future<(Map<String, dynamic>, String)> _load() async {
    final Uri uri = _contentsUri.replace(
      queryParameters: <String, String>{'ref': AppConfig.githubCrmBranch},
    );
    final http.Response res =
        await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 25));
    if (res.statusCode != 200) {
      throw crmExceptionFromStatus(res.statusCode, res.body);
    }
    try {
      final Map<String, dynamic> meta = jsonDecode(res.body) as Map<String, dynamic>;
      final String sha = meta['sha'] as String;
      final String encoded = (meta['content'] as String? ?? '').replaceAll('\n', '');
      final String raw = utf8.decode(base64.decode(encoded));
      final Map<String, dynamic> doc = raw.trim().isEmpty
          ? <String, dynamic>{'version': 1, 'contacts': <dynamic>[]}
          : jsonDecode(raw) as Map<String, dynamic>;
      doc.putIfAbsent('version', () => 1);
      doc.putIfAbsent('contacts', () => <dynamic>[]);
      doc.putIfAbsent('custom_statuses', () => <dynamic>[]);
      return (doc, sha);
    } catch (_) {
      throw const CrmServiceException(
        CrmErrorCode.malformed,
        'CRM file is not valid JSON.',
      );
    }
  }

  Future<void> _save(Map<String, dynamic> doc, String sha, String message) async {
    doc['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final String encoded = base64.encode(utf8.encode(jsonEncode(doc)));
    final http.Response res = await _client
        .put(
          _contentsUri,
          headers: _headers,
          body: jsonEncode(<String, dynamic>{
            'message': message,
            'content': encoded,
            'sha': sha,
            'branch': AppConfig.githubCrmBranch,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 409) {
      throw crmExceptionFromStatus(res.statusCode, res.body);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw crmExceptionFromStatus(res.statusCode, res.body);
    }
  }

  /// Applies a mutation with optimistic-lock retry on HTTP 409 SHA conflicts.
  Future<void> _saveWithRetry(
    void Function(Map<String, dynamic> doc) mutate,
    String message,
  ) async {
    for (int attempt = 0; attempt < _maxConflictRetries; attempt++) {
      final (Map<String, dynamic> doc, String sha) = await _load();
      mutate(doc);
      try {
        await _save(doc, sha, message);
        return;
      } on CrmServiceException catch (e) {
        if (e.code != CrmErrorCode.conflict || attempt == _maxConflictRetries - 1) {
          rethrow;
        }
      }
    }
  }

  // --- LeadsCrmService ------------------------------------------------------

  @override
  Future<List<CrmContact>> listLeads() async {
    final (Map<String, dynamic> doc, _) = await _load();
    return _contacts(doc)
        .map((Map<String, dynamic> c) => CrmContact.fromJson(c))
        .toList();
  }

  @override
  Future<List<CrmInteraction>> history(String contactRef) async {
    final (Map<String, dynamic> doc, _) = await _load();
    final Map<String, dynamic>? contact = _find(doc, contactRef);
    if (contact == null) {
      throw CrmServiceException(
        CrmErrorCode.notFound,
        'Contact "$contactRef" not found in CRM.',
      );
    }
    return _interactions(contact);
  }

  @override
  Future<CrmWriteResult> upsertLead(
    Extraction extraction, {
    String? transcript,
    String? captureId,
  }) async {
    try {
      String action = 'merged';
      String contactId = '';
      String contactName = extraction.client;

      await _saveWithRetry((Map<String, dynamic> doc) {
        final (String act, Map<String, dynamic> contact) =
            _findOrCreate(doc, extraction.client);
        action = act;
        contactId = contact['id']?.toString() ?? '';
        contactName = contact['name']?.toString() ?? extraction.client;

        if (extraction.dealStageChange != null) {
          contact['status'] = extraction.dealStageChange;
        }
        if (extraction.followUpDate != null) {
          contact['next_follow_up'] =
              extraction.followUpDate!.toIso8601String().split('T').first;
        }
        contact['sentiment'] = extraction.sentiment.wire;
        contact['updated_at'] = DateTime.now().toUtc().toIso8601String();

        final List<dynamic> comments =
            contact.putIfAbsent('comments', () => <dynamic>[]) as List<dynamic>;
        final String commentId = captureId ?? _newUuid();
        if (_hasComment(comments, commentId)) return;

        comments.add(<String, dynamic>{
          'id': commentId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'author': 'Mr. Rex (mobile)',
          'body': (transcript == null || transcript.isEmpty)
              ? extraction.summary
              : '${extraction.summary}\n\n"$transcript"',
          'subject': '',
          'meeting_link': '',
          'source': 'mobile',
          'type': 'comment',
        });
      }, 'mobile: $action $contactName');

      return CrmWriteResult(
        ok: true,
        contactId: contactId,
        contactName: contactName,
        action: action,
        webUrl: AppConfig.hasCrmWeb ? AppConfig.crmWebUrl : null,
      );
    } on CrmServiceException catch (e) {
      return CrmWriteResult.failure(e.message);
    } catch (e) {
      return CrmWriteResult.failure(e.toString());
    }
  }

  // --- helpers --------------------------------------------------------------

  List<Map<String, dynamic>> _contacts(Map<String, dynamic> doc) =>
      (doc['contacts'] as List<dynamic>).whereType<Map<String, dynamic>>().toList();

  Map<String, dynamic>? _find(Map<String, dynamic> doc, String ref) {
    final String r = ref.trim().toLowerCase();
    for (final Map<String, dynamic> c in _contacts(doc)) {
      if (c['id']?.toString().toLowerCase() == r) return c;
      if (c['name']?.toString().toLowerCase() == r) return c;
      if (c['company']?.toString().toLowerCase() == r) return c;
    }
    return null;
  }

  (String, Map<String, dynamic>) _findOrCreate(Map<String, dynamic> doc, String name) {
    final Map<String, dynamic>? existing = _find(doc, name);
    if (existing != null) return ('merged', existing);
    final Map<String, dynamic> contact = <String, dynamic>{
      'id': _newUuid(),
      'name': name,
      'company': name,
      'status': 'new',
      'deal_status': 'open',
      'source': 'mobile',
      'tags': <String>['mobile'],
      'email_events': <dynamic>[],
      'comments': <dynamic>[],
      'contact_people': <dynamic>[],
      'invoices': <dynamic>[],
      'meetings': <dynamic>[],
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    (doc['contacts'] as List<dynamic>).add(contact);
    return ('created', contact);
  }

  bool _hasComment(List<dynamic> comments, String id) =>
      comments.whereType<Map<String, dynamic>>().any(
            (Map<String, dynamic> c) => c['id']?.toString() == id,
          );

  List<CrmInteraction> _interactions(Map<String, dynamic> contact) {
    final List<CrmInteraction> out = <CrmInteraction>[];
    for (final String key in <String>['comments', 'interactions', 'emails', 'email_events']) {
      final List<dynamic> list = (contact[key] as List<dynamic>?) ?? <dynamic>[];
      out.addAll(list.whereType<Map<String, dynamic>>().map(CrmInteraction.fromJson));
    }
    out.sort((CrmInteraction a, CrmInteraction b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  static String _newUuid() {
    final Random r = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int v) => v.toRadixString(16).padLeft(2, '0');
    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}'
        '${hex(bytes[14])}${hex(bytes[15])}';
  }
}
